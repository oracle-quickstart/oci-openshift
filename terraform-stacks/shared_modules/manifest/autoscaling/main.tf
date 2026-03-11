terraform {
  required_version = ">= 1.0"
}

locals {
  cert_manager_version = "v1.16.3"

  autoscaling_operator_configmap = <<EOT
# 10-autoscaling-operator-configs.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: oci-capi-operator-config
  namespace: oci-capi-operator
data:
  CAPI_VERSION: "${var.capi_version}"
  CAPOCI_VERSION: "${var.capoci_version}"
  CERT_MANAGER_VERSION: "${local.cert_manager_version}"
  API_SERVER_LOAD_BALANCER_ID: "${var.op_lb_openshift_api_lb}"
  AUTOSCALER_CPUS: "${var.autoscalar_node_ocpus}"
  AUTOSCALER_DEFINED_TAGS_NAMESPACE: "${var.autoscaler_defined_tags_namespace}"
  AUTOSCALER_MAX_NODES: "${var.autoscalar_node_maximum_count}"
  AUTOSCALER_MEMORY: "${var.autoscalar_node_memory}"
  AUTOSCALER_MIN_NODES: "${var.autoscalar_node_minimum_count}"
  AUTOSCALER_SHAPE: "${var.autoscalar_node_shape}"
  BARE_METAL_SUBNET_ID: "${var.bare_metal_subnet_id}"
  BARE_METAL_SUBNET_NAME: "${var.bare_metal_subnet_name}"
  COMPARTMENT_ID: "${var.compartment_ocid}"
  CONTROL_PLANE_ENDPOINT: "${var.op_lb_openshift_api_lb_ip_addr}"
  IMAGE_ID: "${var.autoscalar_node_image_id}"
  NETWORK_SECURITY_GROUP_ID: "${var.op_network_security_group_cluster_lb_nsg}"
  CLUSTER_NETWORK_CIDR_BLOCK: "${var.cluster_network_cidr_block}"
  SERVICE_NETWORK_CIDR_BLOCK: "${var.service_network_cidr_block}"
  OCI_REGION: "${var.region}"
  OCI_TENANCY_ID: "${var.tenancy_ocid}"
  OCI_USE_INSTANCE_PRINCIPAL: "true"
  SUBNET_ID: "${var.op_subnet_private_ocp}"
  OCP_SUBNET_ID: "${var.op_subnet_private_ocp}"
  OCP_SUBNET_NAME: "${var.ocp_subnet_name}"
  VCN_ID: "${var.op_vcn_id}"
EOT

  autoscaling_operator_custom_resource = <<EOT
# 13-ociclusterautoscaler.yaml
apiVersion: capi.openshift.io/v1alpha1
kind: OCIClusterAutoscaler
metadata:
  name: ociclusterautoscaler
  namespace: oci-capi-operator
spec:
  autoscaling:
    imageId: "${var.autoscalar_node_image_id}"
    maxNodes: ${var.autoscalar_node_maximum_count}
    minNodes: ${var.autoscalar_node_minimum_count}
    shape: "${var.autoscalar_node_shape}"
    shapeConfig:
      cpus: ${var.autoscalar_node_ocpus}
      memory: ${var.autoscalar_node_memory}
EOT

  autoscaling_operator_provider_installer = <<EOT
# 12-autoscaling-operator-provider-installer.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: oci-capi-operator-provider-installer
  namespace: oci-capi-operator
spec:
  backoffLimit: 4
  ttlSecondsAfterFinished: 86400
  template:
    spec:
      restartPolicy: OnFailure
      serviceAccountName: oci-capi-operator-controller-manager
      containers:
      - name: provider-installer
        image: quay.io/openshift/origin-cli:4.20
        envFrom:
        - configMapRef:
            name: oci-capi-operator-config
        command:
        - /bin/sh
        - -ec
        - |
          echo "Installing cert-manager $${CERT_MANAGER_VERSION}"
          oc apply -f "https://github.com/cert-manager/cert-manager/releases/download/$${CERT_MANAGER_VERSION}/cert-manager.yaml"
          oc wait --for=condition=Established crd/certificates.cert-manager.io --timeout=5m
          oc rollout status deployment/cert-manager -n cert-manager --timeout=5m
          oc rollout status deployment/cert-manager-cainjector -n cert-manager --timeout=5m
          oc rollout status deployment/cert-manager-webhook -n cert-manager --timeout=5m

          echo "Installing Cluster API $${CAPI_VERSION}"
          curl -LfsS "https://github.com/kubernetes-sigs/cluster-api/releases/download/$${CAPI_VERSION}/core-components.yaml" -o /tmp/capi-core-components.yaml
          sed \
            -e 's|$${CAPI_DIAGNOSTICS_ADDRESS:=:8443}|:8443|g' \
            -e 's|$${CAPI_INSECURE_DIAGNOSTICS:=false}|false|g' \
            -e 's|$${EXP_MACHINE_POOL:=true}|true|g' \
            -e 's|$${CLUSTER_TOPOLOGY:=false}|false|g' \
            -e 's|$${EXP_RUNTIME_SDK:=false}|false|g' \
            -e 's|$${EXP_MACHINE_SET_PREFLIGHT_CHECKS:=true}|true|g' \
            -e 's|$${EXP_MACHINE_WAITFORVOLUMEDETACH_CONSIDER_VOLUMEATTACHMENTS:=true}|true|g' \
            -e 's|$${EXP_PRIORITY_QUEUE:=false}|false|g' \
            -e 's|$${EXP_RECONCILER_RATE_LIMITING:=false}|false|g' \
            -e 's|$${EXP_IN_PLACE_UPDATES:=false}|false|g' \
            -e 's|$${EXP_MACHINE_TAINT_PROPAGATION:=false}|false|g' \
            -e 's|name: capi-controller-manager|name: capi-manager|g' \
            /tmp/capi-core-components.yaml | oc apply -f -
          oc patch clusterrole capi-manager-role --type=json -p='[
            {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["pods"],"verbs":["get"]}},
            {"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["nodes"],"verbs":["get","list","watch","patch","update"]}}
          ]'
          oc rollout status deployment/capi-manager -n capi-system --timeout=10m

          echo "Creating OCIClusterAutoscaler custom resource"
          oc wait --for=condition=Established crd/ociclusterautoscalers.capi.openshift.io --timeout=5m
          cat <<'EOF' | oc apply -f -
          ${replace(trimspace(local.autoscaling_operator_custom_resource), "\n", "\n          ")}
          EOF

          echo "Waiting for CAPOCI auth configuration"
          for i in $(seq 1 120); do
            if oc get secret capoci-auth-config -n cluster-api-provider-oci-system >/dev/null 2>&1; then
              break
            fi
            if [ "$i" = "120" ]; then
              echo "Timed out waiting for capoci-auth-config"
              exit 1
            fi
            sleep 5
          done

          echo "Installing Cluster API Provider OCI $${CAPOCI_VERSION}"
          curl -LfsS "https://github.com/oracle/cluster-api-provider-oci/releases/download/$${CAPOCI_VERSION}/infrastructure-components.yaml" -o /tmp/capoci-infrastructure-components.yaml
          sed \
            -e 's|$${K8S_CP_LABEL:=node-role.kubernetes.io/control-plane}|node-role.kubernetes.io/control-plane|g' \
            -e 's|$${EXP_MACHINE_POOL:=true}|true|g' \
            -e 's|$${LOG_FORMAT:=text}|text|g' \
            -e 's|$${INIT_OCI_CLIENTS_ON_STARTUP:=true}|false|g' \
            -e 's|$${ENABLE_INSTANCE_METADATA_SERVICE_LOOKUP:=false}|true|g' \
            /tmp/capoci-infrastructure-components.yaml |
            awk '
              BEGIN { doc = "" }
              /^---[[:space:]]*$/ {
                if (doc !~ /kind:[[:space:]]*Secret/ || doc !~ /name:[[:space:]]*capoci-auth-config/) {
                  printf "%s---\n", doc
                }
                doc = ""
                next
              }
              { doc = doc $0 "\n" }
              END {
                if (doc != "" && (doc !~ /kind:[[:space:]]*Secret/ || doc !~ /name:[[:space:]]*capoci-auth-config/)) {
                  printf "%s", doc
                }
              }
            ' | oc apply -f -
          oc patch deployment/capoci-controller-manager -n cluster-api-provider-oci-system --type=merge -p '{"spec":{"template":{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}}}'
          oc rollout status deployment/capoci-controller-manager -n cluster-api-provider-oci-system --timeout=10m
EOT

  autoscaling_operator_runtime_bundle = join("\n---\n", [
    trimspace(trimsuffix(trimspace(file("${path.module}/../manifests/09-autoscaling-operator-runtime.yml")), "---")),
    trimspace(local.autoscaling_operator_configmap),
    trimspace(local.autoscaling_operator_provider_installer),
  ])
}

output "autoscaling_manifest" {
  description = "Autoscaling runtime manifest (operator resources + configmap) to apply after installation convergence."
  value       = local.autoscaling_operator_runtime_bundle

  precondition {
    condition     = var.autoscalar_node_minimum_count >= 0 && var.autoscalar_node_maximum_count >= var.autoscalar_node_minimum_count
    error_message = "The autoscalar_node_minimum_count value must be greater than or equal to 0, and autoscalar_node_maximum_count must be greater than or equal to autoscalar_node_minimum_count."
  }
}
