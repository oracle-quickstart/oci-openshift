# OCI OpenShift Autoscaler Guide

The OCI OpenShift Autoscaler is available for OpenShift on OCI. Use this guide for Day 0 installation-time enablement and Day 1 post-install enablement.

## Prerequisites

- An OpenShift cluster, or a new cluster being created with the `create-cluster` stack.
- OCI permissions to upload to Object Storage and create a read PAR URL.
- OCI permissions to import custom images.
- OCI permissions to read the VCN, subnets, load balancers, and network security groups used by the cluster.
- The `create-cluster` stack for Day 0, or the `create-autoscaler-operator` stack for Day 1.

## Prepare the Autoscaling RHCOS Image

Download the RHCOS OpenStack qcow2 image that matches the OpenShift version from https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/.

Example for OpenShift 4.22.0:

```sh
curl -LO https://mirror.openshift.com/pub/openshift-v4/x86_64/dependencies/rhcos/4.22/4.22.0/rhcos-4.22.0-x86_64-openstack.x86_64.qcow2.gz
gzip -d rhcos-4.22.0-x86_64-openstack.x86_64.qcow2.gz
```

For VM autoscaling, upload the downloaded qcow2 file to OCI Object Storage, create a read PAR URL for the object, and use that PAR URL as `autoscaler_node_image_source_uri`.

For bare metal autoscaling, patch the qcow2 with iSCSI kernel arguments before uploading it. Run `assets/autoscaler/iscsi.sh` from a Linux host or Linux VM; it uses Linux block device tooling and should not be run directly on macOS.

```sh
sudo ./assets/autoscaler/iscsi.sh rhcos-4.22.0-x86_64-openstack.x86_64.qcow2
```

This creates:

```text
rhcos-4.19.0-x86_64-openstack.x86_64-iscsi.qcow2
```

Upload the `*-iscsi.qcow2` file to Object Storage, create a read PAR URL, and use that PAR URL as `autoscaler_node_image_source_uri`.

## Day 0: Enable Autoscaler During Cluster Creation

Use the `terraform-stacks/create-cluster` stack and set:

```hcl
use_autoscaling_operator = true

autoscaler_node_shape            = "<autoscaling-worker-shape>"
autoscaler_node_image_source_uri = "<object-storage-par-url>"
autoscaler_node_minimum_count    = 1
autoscaler_node_maximum_count    = 10
autoscaler_node_ocpus            = 4
autoscaler_node_memory           = 32
```

Optionally set `autoscaler_pool_identifier = "vm01"` to emit `spec.autoscaling.poolIdentifier` in the `OCIClusterAutoscaler` custom resource. The operator appends it to the CAPI cluster name when naming autoscaler node pool resources, for example `fwvtfa-rgqqh-vm01`. Use up to 5 lowercase letters, numbers, or hyphens; the value must start and end with a lowercase letter or number.

Apply the stack, then complete the OpenShift installation flow.

## Day 1: Enable Autoscaler After Cluster Creation

Use the `terraform-stacks/create-autoscaler-operator` stack.

Required inputs include existing VCN and subnet IDs, cluster name, region, compartment, autoscaler target shape, and `autoscaler_node_image_source_uri`.

After the stack apply completes, export the `autoscaling_manifest` output and apply it to the cluster:

```sh
terraform output -raw autoscaling_manifest > autoscaling-dynamic-output.yml
oc apply -f autoscaling-dynamic-output.yml
```

## Verification

Use the same checks for Day 0 and Day 1:

```sh
oc get ns oci-openshift-autoscaling-operator
oc get pods -n oci-openshift-autoscaling-operator
oc get ociclusterautoscalers.capi.openshift.io -n oci-openshift-autoscaling-operator
oc get ociclusterautoscalers.capi.openshift.io ociclusterautoscaler -n oci-openshift-autoscaling-operator -o yaml
```

Success status:

```yaml
status:
  phase: Ready
  capiInstalled: true
  clusterAutoscalerDeployed: true
```

## Scale Up And Down

The Terraform inputs set the initial autoscaler node limits. For example, `autoscaler_node_maximum_count = 5` creates the `OCIClusterAutoscaler` custom resource with `spec.autoscaling.maxNodes: 5`.

To update the live minimum and maximum autoscaler node limits, patch the `OCIClusterAutoscaler` custom resource:

```sh
oc patch ociclusterautoscaler.capi.openshift.io -n oci-openshift-autoscaling-operator ociclusterautoscaler \
  --type=merge \
  -p '{"spec":{"autoscaling":{"minNodes":1,"maxNodes":3}}}'
```

Verify the updated values:

```sh
oc get ociclusterautoscaler.capi.openshift.io -n oci-openshift-autoscaling-operator ociclusterautoscaler \
  -o jsonpath='{.spec.autoscaling.minNodes}{" "}{.spec.autoscaling.maxNodes}{"\n"}'
```

Watch the autoscaling resources:

```sh
oc get machinedeployments.cluster.x-k8s.io -n oci-openshift-autoscaling-operator
oc get machinesets.cluster.x-k8s.io -n oci-openshift-autoscaling-operator
oc get machines.cluster.x-k8s.io -n oci-openshift-autoscaling-operator -o wide
oc get nodes
```

Cluster Autoscaler scales up when workload pods cannot be scheduled within the configured limits. To scale down, remove or reduce the workload demand and lower `minNodes` or `maxNodes` as needed; CAPI then reconciles the generated `MachineDeployment`, `MachineSet`, and `Machine` resources.

For Day 1 deployments, also update the Terraform variable, re-run `terraform apply`, export `autoscaling_manifest`, and re-apply it when the Terraform output should remain the source of truth:

```sh
terraform output -raw autoscaling_manifest > autoscaling-dynamic-output.yml
oc apply -f autoscaling-dynamic-output.yml
```

## Cleanup

Use this when the autoscaler stack is no longer needed. The cleanup commands below remove CAPI/CAPOCI, autoscaler, cert-manager resources installed for this stack, webhooks, RBAC, namespaces, and CRDs by using `oc` directly; downloading this repository is not required.

First remove workload demand and scale down autoscaler-created capacity when possible:

```sh
oc scale deployment -n default nginx --replicas=0
oc scale md -n oci-openshift-autoscaling-operator <md-name> --replicas=0
oc get ocimachine -n oci-openshift-autoscaling-operator
```

### Remove CAPI/CAPOCI And Autoscaler Resources

Run the full cleanup script:

```sh
export STACK_NAMESPACE=oci-openshift-autoscaling-operator
export AUTOSCALER_NAME=ociclusterautoscaler
export LABEL_SELECTOR="capi.openshift.io/managed-by=${AUTOSCALER_NAME}"
export REQUEST_TIMEOUT=60s

export CAPI_CLUSTER_NAME="$(
  oc get clusters.cluster.x-k8s.io -n ${STACK_NAMESPACE} -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || \
  oc get machinedeployments.cluster.x-k8s.io -n ${STACK_NAMESPACE} -o jsonpath='{.items[0].spec.clusterName}' 2>/dev/null
)"

cleanup_capi_objects() {
  echo "Cleaning CAPI/CAPOCI objects in ${STACK_NAMESPACE}, cluster=${CAPI_CLUSTER_NAME:-<unknown>}"

  for kind in \
    machinedeployments.cluster.x-k8s.io \
    machinesets.cluster.x-k8s.io \
    machines.cluster.x-k8s.io \
    ocimachines.infrastructure.cluster.x-k8s.io \
    ocimachinetemplates.infrastructure.cluster.x-k8s.io \
    clusters.cluster.x-k8s.io \
    ociclusters.infrastructure.cluster.x-k8s.io \
    ociclusteridentities.infrastructure.cluster.x-k8s.io
  do
    oc delete ${kind} -n ${STACK_NAMESPACE} -l "${LABEL_SELECTOR}" \
      --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true
  done

  if [ -n "${CAPI_CLUSTER_NAME}" ]; then
    for kind in \
      machinedeployments.cluster.x-k8s.io \
      machinesets.cluster.x-k8s.io \
      machines.cluster.x-k8s.io \
      ocimachines.infrastructure.cluster.x-k8s.io \
      ocimachinetemplates.infrastructure.cluster.x-k8s.io
    do
      oc delete ${kind} -n ${STACK_NAMESPACE} -l "cluster.x-k8s.io/cluster-name=${CAPI_CLUSTER_NAME}" \
        --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true
    done

    for kind in \
      clusters.cluster.x-k8s.io \
      ociclusters.infrastructure.cluster.x-k8s.io \
      ociclusteridentities.infrastructure.cluster.x-k8s.io
    do
      oc delete ${kind} -n ${STACK_NAMESPACE} ${CAPI_CLUSTER_NAME} \
        --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true
    done
  fi

  for kind in \
    machinedeployments.cluster.x-k8s.io \
    machinesets.cluster.x-k8s.io \
    machines.cluster.x-k8s.io \
    ocimachines.infrastructure.cluster.x-k8s.io \
    ocimachinetemplates.infrastructure.cluster.x-k8s.io \
    clusters.cluster.x-k8s.io \
    ociclusters.infrastructure.cluster.x-k8s.io \
    ociclusteridentities.infrastructure.cluster.x-k8s.io
  do
    oc get ${kind} -n ${STACK_NAMESPACE} -l "${LABEL_SELECTOR}" -o name 2>/dev/null | while read r; do
      oc patch "$r" -n ${STACK_NAMESPACE} --type=merge -p '{"metadata":{"finalizers":[]}}' \
        --request-timeout=${REQUEST_TIMEOUT} || true
    done
  done

  if [ -n "${CAPI_CLUSTER_NAME}" ]; then
    for kind in \
      machinedeployments.cluster.x-k8s.io \
      machinesets.cluster.x-k8s.io \
      machines.cluster.x-k8s.io \
      ocimachines.infrastructure.cluster.x-k8s.io \
      ocimachinetemplates.infrastructure.cluster.x-k8s.io
    do
      oc get ${kind} -n ${STACK_NAMESPACE} -l "cluster.x-k8s.io/cluster-name=${CAPI_CLUSTER_NAME}" -o name 2>/dev/null | while read r; do
        oc patch "$r" -n ${STACK_NAMESPACE} --type=merge -p '{"metadata":{"finalizers":[]}}' \
          --request-timeout=${REQUEST_TIMEOUT} || true
      done
    done

    for kind in \
      clusters.cluster.x-k8s.io \
      ociclusters.infrastructure.cluster.x-k8s.io \
      ociclusteridentities.infrastructure.cluster.x-k8s.io
    do
      oc get ${kind} -n ${STACK_NAMESPACE} ${CAPI_CLUSTER_NAME} -o name 2>/dev/null | while read r; do
        oc patch "$r" -n ${STACK_NAMESPACE} --type=merge -p '{"metadata":{"finalizers":[]}}' \
          --request-timeout=${REQUEST_TIMEOUT} || true
      done
    done
  fi
}

oc delete job -n ${STACK_NAMESPACE} \
  oci-capi-operator-provider-installer \
  oci-capi-operator-activate-after-install \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete deployment -n ${STACK_NAMESPACE} oci-capi-operator-controller-manager \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete ociclusterautoscaler -n ${STACK_NAMESPACE} ${AUTOSCALER_NAME} \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc wait --for=delete ociclusterautoscaler -n ${STACK_NAMESPACE} ${AUTOSCALER_NAME} \
  --timeout=${REQUEST_TIMEOUT} || \
oc patch ociclusterautoscaler -n ${STACK_NAMESPACE} ${AUTOSCALER_NAME} \
  --type=merge -p '{"metadata":{"finalizers":[]}}' \
  --request-timeout=${REQUEST_TIMEOUT} || true

cleanup_capi_objects

oc delete validatingwebhookconfiguration \
  oci-capi-operator-validating-webhook-configuration \
  capoci-validating-webhook-configuration \
  capi-validating-webhook-configuration \
  cert-manager-webhook \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete mutatingwebhookconfiguration \
  oci-capi-operator-mutating-webhook-configuration \
  capoci-mutating-webhook-configuration \
  capi-mutating-webhook-configuration \
  cert-manager-webhook \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete deployment -n ${STACK_NAMESPACE} \
  capi-manager \
  capi-controller-manager \
  oci-cluster-autoscaler \
  capoci-controller-manager \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete deployment -n cert-manager cert-manager cert-manager-cainjector cert-manager-webhook \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

sleep 10
cleanup_capi_objects

oc delete configmap -n ${STACK_NAMESPACE} \
  oci-capi-operator-config \
  oci-capi-operator-runtime-manifest \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete secret -n ${STACK_NAMESPACE} \
  oci-capi-operator-capoci-auth-credentials \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete serviceaccount -n ${STACK_NAMESPACE} \
  oci-capi-operator-controller-manager \
  oci-capi-operator-activator \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete role -n ${STACK_NAMESPACE} \
  oci-capi-operator-leader-election-role \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete rolebinding -n ${STACK_NAMESPACE} \
  oci-capi-operator-leader-election-rolebinding \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete role -n kube-system \
  cert-manager-cainjector:leaderelection \
  cert-manager:leaderelection \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete rolebinding -n kube-system \
  cert-manager-cainjector:leaderelection \
  cert-manager:leaderelection \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete clusterrole \
  oci-capi-operator-manager-role \
  oci-capi-operator-metrics-auth-role \
  oci-capi-operator-metrics-reader \
  oci-capi-operator-ociclusterautoscaler-editor-role \
  oci-capi-operator-ociclusterautoscaler-viewer-role \
  capi-manager-role \
  capi-aggregated-manager-role \
  capoci-manager-role \
  capoci-metrics-reader \
  capoci-proxy-role \
  oci-cluster-autoscaler \
  oci-cluster-autoscaler-extra \
  cert-manager-cainjector \
  cert-manager-cluster-view \
  cert-manager-controller-approve:cert-manager-io \
  cert-manager-controller-certificates \
  cert-manager-controller-certificatesigningrequests \
  cert-manager-controller-challenges \
  cert-manager-controller-clusterissuers \
  cert-manager-controller-ingress-shim \
  cert-manager-controller-issuers \
  cert-manager-controller-orders \
  cert-manager-edit \
  cert-manager-view \
  cert-manager-webhook:subjectaccessreviews \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete clusterrolebinding \
  oci-capi-operator-manager-rolebinding \
  oci-capi-operator-metrics-auth-rolebinding \
  oci-capi-operator-oci-capi-operator-admin \
  oci-capi-operator-activator-admin \
  capi-manager-rolebinding \
  capoci-manager-rolebinding \
  capoci-proxy-rolebinding \
  oci-capi-operator-capoci-privileged-scc \
  oci-cluster-autoscaler \
  oci-cluster-autoscaler-extra \
  cert-manager-cainjector \
  cert-manager-controller-approve:cert-manager-io \
  cert-manager-controller-certificates \
  cert-manager-controller-certificatesigningrequests \
  cert-manager-controller-challenges \
  cert-manager-controller-clusterissuers \
  cert-manager-controller-ingress-shim \
  cert-manager-controller-issuers \
  cert-manager-controller-orders \
  cert-manager-webhook:subjectaccessreviews \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete scc oci-capi \
  --ignore-not-found=true --request-timeout=${REQUEST_TIMEOUT} || true

oc delete namespace \
  ${STACK_NAMESPACE} \
  cert-manager \
  capi-system \
  cluster-api-provider-oci-system \
  oci-capi-operator \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

sleep 10
cleanup_capi_objects

oc delete crd ociclusterautoscalers.capi.openshift.io \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete crd -l cluster.x-k8s.io/provider \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

oc delete crd \
  certificaterequests.cert-manager.io \
  certificates.cert-manager.io \
  challenges.acme.cert-manager.io \
  clusterissuers.cert-manager.io \
  issuers.cert-manager.io \
  orders.acme.cert-manager.io \
  --ignore-not-found=true --wait=false --request-timeout=${REQUEST_TIMEOUT} || true

for ns in ${STACK_NAMESPACE} cert-manager capi-system cluster-api-provider-oci-system oci-capi-operator; do
  if oc get ns "$ns" >/dev/null 2>&1; then
    oc patch ns "$ns" --type=json -p '[{"op":"remove","path":"/spec/finalizers"}]' \
      --request-timeout=${REQUEST_TIMEOUT} || true
  fi
done
```

Verify cleanup:

```sh
oc get ns oci-openshift-autoscaling-operator oci-capi-operator capi-system cluster-api-provider-oci-system cert-manager --ignore-not-found
oc api-resources | grep ociclusterautoscalers || true
oc get crd | grep -E 'cluster\.x-k8s\.io|infrastructure\.cluster\.x-k8s\.io|cert-manager\.io|acme\.cert-manager\.io' || true
```

Expected:

- No listed autoscaler/CAPI/CAPOCI/cert-manager namespaces remain.
- No `OCIClusterAutoscaler` API remains.
- No CAPI/CAPOCI/cert-manager CRDs remain.

## Monitor And Investigate

The autoscaler manifest installs the OCI CAPI operator in the `oci-openshift-autoscaling-operator` namespace. After the `OCIClusterAutoscaler` custom resource is created, the operator installs or uses CAPI, CAPOCI, cert-manager, and Cluster Autoscaler. The operator then creates autoscaling resources in `oci-openshift-autoscaling-operator`, including `OCICluster`, `OCIClusterIdentity`, bootstrap secret, `OCIMachineTemplate`, `MachineDeployment`, and `MachineHealthCheck`.

When workload pods cannot be scheduled, Cluster Autoscaler increases the `MachineDeployment` replica count. CAPI creates `Machine` and `MachineSet` resources. CAPOCI then provisions OCI compute instances. After the instance boots, the worker fetches ignition, submits CSRs, and joins the OpenShift cluster.

Export environment variables:

```sh
export STACK_NAMESPACE=oci-openshift-autoscaling-operator
export AUTOSCALER_NAME=ociclusterautoscaler
```

Check the provisioning chain:

```sh
oc get ociclusterautoscaler -n ${STACK_NAMESPACE} ${AUTOSCALER_NAME} -o yaml
oc get machinedeployments.cluster.x-k8s.io -n ${STACK_NAMESPACE}
oc get machinesets.cluster.x-k8s.io -n ${STACK_NAMESPACE}
oc get machines.cluster.x-k8s.io -n ${STACK_NAMESPACE} -o wide
oc get ocimachines.infrastructure.cluster.x-k8s.io -n ${STACK_NAMESPACE} -o wide
oc get nodes -o wide
```

Check events for provisioning failures:

```sh
oc get events -n ${STACK_NAMESPACE} --sort-by=.lastTimestamp

# For a specific stuck Machine:
export MACHINE_NAME=<machine-name>
oc describe machine.cluster.x-k8s.io -n ${STACK_NAMESPACE} ${MACHINE_NAME}
oc get event -n ${STACK_NAMESPACE} \
  --field-selector involvedObject.name=${MACHINE_NAME} \
  --sort-by=.lastTimestamp

# Find the related OCIMachine:
oc get machine.cluster.x-k8s.io -n ${STACK_NAMESPACE} ${MACHINE_NAME} \
  -o jsonpath='{.spec.infrastructureRef.name}{"\n"}'

export OCI_MACHINE_NAME=<ocimachine-name>
oc describe ocimachine.infrastructure.cluster.x-k8s.io -n ${STACK_NAMESPACE} ${OCI_MACHINE_NAME}
oc get ocimachine.infrastructure.cluster.x-k8s.io -n ${STACK_NAMESPACE} ${OCI_MACHINE_NAME} -o yaml
```

Check controller logs:

```sh
# OCI CAPI operator logs
oc logs -n ${STACK_NAMESPACE} \
  deployment/oci-capi-operator-controller-manager \
  -c manager \
  --tail=300

# CAPOCI provider logs: most useful for OCI provisioning errors
oc logs -n ${STACK_NAMESPACE} \
  deployment/capoci-controller-manager \
  --tail=500

# CAPI controller logs
oc logs -n ${STACK_NAMESPACE} \
  deployment/capi-manager \
  --tail=500

# Cluster Autoscaler logs: useful if no Machine was created
oc logs -n ${STACK_NAMESPACE} \
  deployment/oci-cluster-autoscaler \
  --tail=500
```

Common failure signals:

```sh
# No new Machine:
oc logs -n ${STACK_NAMESPACE} deployment/oci-cluster-autoscaler --tail=500

# Machine exists, but OCIMachine has no providerID:
oc describe ocimachine.infrastructure.cluster.x-k8s.io -n ${STACK_NAMESPACE} ${OCI_MACHINE_NAME}
oc logs -n ${STACK_NAMESPACE} deployment/capoci-controller-manager --tail=500

# OCI instance exists, but no OpenShift node joined:
oc get csr
oc get nodes
oc get mcp
oc get co machine-config
```
