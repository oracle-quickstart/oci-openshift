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
oc get ns oci-openshift-autoscaling-operator cert-manager
oc get pods -n oci-openshift-autoscaling-operator
oc get pods -n cert-manager
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

## Update Autoscaler Node Limits

The Terraform inputs set the initial autoscaler node limits. For example, `autoscaler_node_maximum_count = 5` creates the `OCIClusterAutoscaler` custom resource with `spec.autoscaling.maxNodes: 5`.

To change the live limit after the stack has been applied, patch the `OCIClusterAutoscaler` custom resource:

```sh
oc patch ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  --type merge \
  -p '{"spec":{"autoscaling":{"minNodes":1,"maxNodes":8}}}'
```

Verify the updated value:

```sh
oc get ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  -o jsonpath='{.spec.autoscaling.minNodes}{" "}{.spec.autoscaling.maxNodes}{"\n"}'
```

For Day 1 deployments, also update the Terraform variable, re-run `terraform apply`, export `autoscaling_manifest`, and re-apply it when you want the Terraform output to remain the source of truth:

```sh
terraform output -raw autoscaling_manifest > autoscaling-dynamic-output.yml
oc apply -f autoscaling-dynamic-output.yml
```

## Cleanup

Use cleanup when the autoscaler stack is no longer needed. First scale down autoscaler-created capacity so CAPI can delete provider resources cleanly, then choose either the Makefile targets from this repository or the direct `oc` commands below.

### Scale Down Completely

To ensure no instances are left dangling, completely scale down CAPI-installed instances first.

Scale down the test workload:

```sh
oc scale deployment -n default nginx --replicas=0
```

Scale down the MachineDeployment, if necessary:

```sh
oc scale md -n oci-openshift-autoscaling-operator <md-name> --replicas=0
```

Ensure all `OCIMachine` CRs are removed:

```sh
oc get ocimachine -n oci-openshift-autoscaling-operator
```

### Operator-Only Uninstall

Use this when you only want to remove the OCI CAPI Operator resources and keep CAPI/CAPOCI installed. The Day 0 shortcut also removes the dedicated `oci-openshift-autoscaling-operator` namespace:

```sh
make cleanup-autoscaler
```

If your autoscaler CR name or namespace is not the Day 0 default, use the lower-level target:

```sh
make cleanup-operator-only CONFIRM_OPERATOR_ONLY_TEARDOWN=true AUTOSCALER_NAMESPACE=<namespace> AUTOSCALER_NAME=<name> REQUEST_TIMEOUT=60s
```

If the Makefile is not available, run the direct commands:

```sh
oc delete ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=false

oc patch ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  --type merge \
  -p '{"metadata":{"finalizers":[]}}' || true

oc delete deployment oci-capi-operator-controller-manager \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete job oci-capi-operator-provider-installer oci-capi-operator-activate-after-install \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=false

oc delete configmap oci-capi-operator-config oci-capi-operator-runtime-manifest \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete secret oci-capi-operator-capoci-auth-credentials \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete serviceaccount oci-capi-operator-controller-manager oci-capi-operator-activator \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete role oci-capi-operator-leader-election-role \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete rolebinding oci-capi-operator-leader-election-rolebinding \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete clusterrole \
  oci-capi-operator-manager-role \
  oci-capi-operator-metrics-auth-role \
  oci-capi-operator-metrics-reader \
  oci-capi-operator-ociclusterautoscaler-editor-role \
  oci-capi-operator-ociclusterautoscaler-viewer-role \
  --ignore-not-found=true

oc delete clusterrolebinding \
  oci-capi-operator-manager-rolebinding \
  oci-capi-operator-metrics-auth-rolebinding \
  oci-capi-operator-oci-capi-operator-admin \
  oci-capi-operator-activator-admin \
  oci-capi-operator-capoci-privileged-scc \
  --ignore-not-found=true

oc delete validatingwebhookconfiguration oci-capi-operator-validating-webhook-configuration \
  --ignore-not-found=true \
  --wait=false

oc delete mutatingwebhookconfiguration oci-capi-operator-mutating-webhook-configuration \
  --ignore-not-found=true \
  --wait=false

oc delete crd ociclusterautoscalers.capi.openshift.io \
  --ignore-not-found=true

oc delete namespace oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=false
```

### Remove CAPI and Autoscaler Deployments

This is a destructive provider teardown. It stops the operator, deletes the selected `OCIClusterAutoscaler` CR, clears provider-managed resource finalizers before CRD deletion, then removes the single autoscaler namespace, provider CRDs, provider-installer resources, cert-manager resources installed by the Day 0 provider installer, and related RBAC/CRDs.

For the Day 0 manifest defaults:

```sh
make cleanup-autoscaler-full
```

If your autoscaler CR name or namespace is not the Day 0 default, use:

```sh
make cleanup-capi-autoscaler CONFIRM_PROVIDER_TEARDOWN=true AUTOSCALER_NAMESPACE=<namespace> AUTOSCALER_NAME=<name> REQUEST_TIMEOUT=60s
```

If the Makefile is not available and you want to remove the autoscaler plus the CAPI/CAPOCI provider stack, run the direct commands:

```sh
oc delete job oci-capi-operator-provider-installer \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=false

oc delete deployment oci-capi-operator-controller-manager \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=true

oc delete ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true \
  --wait=false

oc patch ociclusterautoscaler ociclusterautoscaler \
  -n oci-openshift-autoscaling-operator \
  --type merge \
  -p '{"metadata":{"finalizers":[]}}' || true

for resource in \
  machines.cluster.x-k8s.io \
  machinesets.cluster.x-k8s.io \
  machinedeployments.cluster.x-k8s.io \
  ocimachines.infrastructure.cluster.x-k8s.io \
  ocimachinetemplates.infrastructure.cluster.x-k8s.io \
  clusters.cluster.x-k8s.io \
  ociclusters.infrastructure.cluster.x-k8s.io \
  ociclusteridentities.infrastructure.cluster.x-k8s.io; do
  oc delete "$resource" \
    -n oci-openshift-autoscaling-operator \
    -l capi.openshift.io/managed-by=ociclusterautoscaler \
    --ignore-not-found=true \
    --wait=false
done

for resource in \
  machines.cluster.x-k8s.io \
  machinesets.cluster.x-k8s.io \
  machinedeployments.cluster.x-k8s.io \
  ocimachines.infrastructure.cluster.x-k8s.io \
  ocimachinetemplates.infrastructure.cluster.x-k8s.io \
  clusters.cluster.x-k8s.io \
  ociclusters.infrastructure.cluster.x-k8s.io \
  ociclusteridentities.infrastructure.cluster.x-k8s.io; do
  oc get "$resource" \
    -n oci-openshift-autoscaling-operator \
    -l capi.openshift.io/managed-by=ociclusterautoscaler \
    --no-headers \
    -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name' 2>/dev/null | while read namespace name; do
      [ -n "$name" ] || continue
      oc patch "$resource" "$name" \
        -n "$namespace" \
        --type merge \
        -p '{"metadata":{"finalizers":[]}}' || true
    done
done

oc delete deployment capi-manager capi-controller-manager oci-cluster-autoscaler \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete deployment capoci-controller-manager \
  -n oci-openshift-autoscaling-operator \
  --ignore-not-found=true

oc delete deployment cert-manager cert-manager-cainjector cert-manager-webhook \
  -n cert-manager \
  --ignore-not-found=true

oc delete validatingwebhookconfiguration \
  capoci-validating-webhook-configuration \
  capi-validating-webhook-configuration \
  cert-manager-webhook \
  --ignore-not-found=true \
  --wait=false

oc delete mutatingwebhookconfiguration \
  capoci-mutating-webhook-configuration \
  capi-mutating-webhook-configuration \
  cert-manager-webhook \
  --ignore-not-found=true \
  --wait=false

oc delete namespace \
  oci-openshift-autoscaling-operator \
  cert-manager \
  --ignore-not-found=true \
  --wait=false

oc get crd -o name 2>/dev/null | grep -E '/((clusterclasses|clusters|machinedeployments|machinedrainrules|machinehealthchecks|machinepools|machines|machinesets)\.cluster\.x-k8s\.io|(clusterresourcesetbindings|clusterresourcesets)\.addons\.cluster\.x-k8s\.io|extensionconfigs\.runtime\.cluster\.x-k8s\.io|(ocicluster|ocimachine|ocimanaged|ocivirtual).*\.infrastructure\.cluster\.x-k8s\.io|ociclusterautoscalers\.capi\.openshift\.io|(certificaterequests|certificates|clusterissuers|issuers)\.cert-manager\.io|(challenges|orders)\.acme\.cert-manager\.io)$' | while read crd; do
  oc delete "$crd" --ignore-not-found=true
done || true

oc get clusterrole -o name 2>/dev/null | grep -E '/(oci-capi|capi-|capoci-|cert-manager|oci-cluster-autoscaler)' | while read role; do
  oc delete "$role" --ignore-not-found=true
done || true

oc get clusterrolebinding -o name 2>/dev/null | grep -E '/(oci-capi|capi-|capoci-|cert-manager|oci-cluster-autoscaler)' | while read rolebinding; do
  oc delete "$rolebinding" --ignore-not-found=true
done || true

oc delete role cert-manager-cainjector:leaderelection cert-manager:leaderelection \
  -n kube-system \
  --ignore-not-found=true

oc delete rolebinding cert-manager-cainjector:leaderelection cert-manager:leaderelection \
  -n kube-system \
  --ignore-not-found=true

oc delete scc oci-capi \
  --ignore-not-found=true

for namespace in oci-openshift-autoscaling-operator cert-manager; do
  if oc get namespace "$namespace" >/dev/null 2>&1; then
    oc patch namespace "$namespace" \
      --type json \
      -p '[{"op":"remove","path":"/spec/finalizers"}]' || true
  fi
done
```

For stuck deletions, the target removes provider finalizers only after attempting normal deletion and waiting up to `REQUEST_TIMEOUT`. It first uses `AUTOSCALER_LABEL_SELECTOR`, then discovers CAPI cluster names from `AUTOSCALER_CLUSTER_NAMESPACE` and cleans generated resources such as `MachineSet` objects using `cluster.x-k8s.io/cluster-name`. If discovery is not possible, pass the CAPI cluster name explicitly:

```sh
make cleanup-capi-autoscaler \
  CONFIRM_PROVIDER_TEARDOWN=true \
  AUTOSCALER_NAMESPACE=oci-openshift-autoscaling-operator \
  AUTOSCALER_NAME=ociclusterautoscaler \
  AUTOSCALER_CLUSTER_NAME=<capi-cluster-name> \
  REQUEST_TIMEOUT=60s
```

Check the OCI CAPI Operator logs:

```sh
oc logs -n oci-openshift-autoscaling-operator deploy/oci-capi-operator-controller-manager
```

Verify cleanup:

```sh
oc get ns oci-openshift-autoscaling-operator cert-manager --ignore-not-found
oc get ociclusterautoscalers.capi.openshift.io -A 2>/dev/null || true
oc get crd | grep -E 'ociclusterautoscalers\.capi\.openshift\.io|clusterclasses\.cluster\.x-k8s\.io|machinedeployments\.cluster\.x-k8s\.io|machinesets\.cluster\.x-k8s\.io|machines\.cluster\.x-k8s\.io|ocimachines\.infrastructure\.cluster\.x-k8s\.io|ociclusters\.infrastructure\.cluster\.x-k8s\.io|cert-manager\.io|acme\.cert-manager\.io' || true
oc get clusterrole,clusterrolebinding | grep -E 'oci-capi|capi-|capoci|cert-manager|oci-cluster-autoscaler' || true
oc get role,rolebinding -n kube-system | grep -E 'cert-manager.*leaderelection' || true
oc get scc | grep -E 'oci-capi' || true
oc get deployment -A | grep -E 'oci-capi|capi-manager|capoci|oci-cluster-autoscaler|cert-manager' || true
```

OpenShift-owned CRDs such as `ipaddressclaims.ipam.cluster.x-k8s.io` or unrelated platform CRDs such as `metal3remediations.infrastructure.cluster.x-k8s.io` may still exist and are not owned by this cleanup target. The OpenShift-owned `openshift-machine-api/cluster-autoscaler-operator` deployment is also expected to remain.
