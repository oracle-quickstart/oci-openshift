# OCI OpenShift Autoscaler Beta Guide

The OCI OpenShift Autoscaler is available as a beta feature for OpenShift on OCI. Use this guide for Day 0 installation-time enablement and Day 1 post-install enablement.

## Prerequisites

- An OpenShift cluster, or a new cluster being created with the `create-cluster` stack.
- OCI permissions to upload to Object Storage and create a read PAR URL.
- OCI permissions to import custom images.
- OCI permissions to read the VCN, subnets, load balancers, and network security groups used by the cluster.
- The `create-cluster-v1.5.1.zip` stack for Day 0, or the `create-autoscaler-operator-v1.5.1.zip` stack for Day 1.

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
oc get ns oci-capi-operator capi-system cluster-api-provider-oci-system
oc get pods -n oci-capi-operator
oc get pods -n capi-system
oc get pods -n cluster-api-provider-oci-system
oc get ociclusterautoscalers.capi.openshift.io -n oci-capi-operator
oc get ociclusterautoscalers.capi.openshift.io ociclusterautoscaler -n oci-capi-operator -o yaml
```

Success status:

```yaml
status:
  phase: Ready
  capiInstalled: true
  clusterAutoscalerDeployed: true
```

## Cleanup

### Scale Down Completely

To ensure no instances are left dangling, completely scale down CAPI-installed instances first.

Scale down the test workload:

```sh
oc scale deployment -n default nginx --replicas=0
```

Scale down the MachineDeployment, if necessary:

```sh
oc scale md -n capi-system <md-name> --replicas=0
```

Ensure all `OCIMachine` CRs are removed:

```sh
oc get ocimachine -n capi-system
```

### Operator-Only Uninstall

Use this when you only want to remove the OCI CAPI Operator resources and keep CAPI/CAPOCI installed. The Day 0 shortcut also removes the dedicated `oci-capi-operator` namespace:

```sh
make cleanup-autoscaler
```

If your autoscaler CR name or namespace is not the Day 0 default, use the lower-level target:

```sh
make cleanup-operator-only CONFIRM_OPERATOR_ONLY_TEARDOWN=true AUTOSCALER_NAMESPACE=<namespace> AUTOSCALER_NAME=<name> REQUEST_TIMEOUT=60s
```

### Remove CAPI and Autoscaler Deployments

This is a destructive provider teardown. It stops the operator, deletes the selected `OCIClusterAutoscaler` CR, clears provider-managed resource finalizers before CRD deletion, then removes CAPI/CAPOCI namespaces, provider CRDs, provider-installer resources, cert-manager resources installed by the Day 0 provider installer, and the OCI CAPI Operator namespace/RBAC/CRD.

For the Day 0 manifest defaults:

```sh
make cleanup-autoscaler-full
```

If your autoscaler CR name or namespace is not the Day 0 default, use:

```sh
make cleanup-capi-autoscaler CONFIRM_PROVIDER_TEARDOWN=true AUTOSCALER_NAMESPACE=<namespace> AUTOSCALER_NAME=<name> REQUEST_TIMEOUT=60s
```

For stuck deletions, the target removes provider finalizers only after attempting normal deletion and waiting up to `REQUEST_TIMEOUT`. It first uses `AUTOSCALER_LABEL_SELECTOR`, then discovers CAPI cluster names from `AUTOSCALER_CLUSTER_NAMESPACE` and cleans generated resources such as `MachineSet` objects using `cluster.x-k8s.io/cluster-name`. If discovery is not possible, pass the CAPI cluster name explicitly:

```sh
make cleanup-capi-autoscaler \
  CONFIRM_PROVIDER_TEARDOWN=true \
  AUTOSCALER_NAMESPACE=oci-capi-operator \
  AUTOSCALER_NAME=ociclusterautoscaler \
  AUTOSCALER_CLUSTER_NAME=<capi-cluster-name> \
  REQUEST_TIMEOUT=60s
```

Check the OCI CAPI Operator logs:

```sh
oc logs -n oci-capi-operator deploy/oci-capi-operator-controller-manager
```

Verify cleanup:

```sh
oc get ns oci-capi-operator capi-system cluster-api-provider-oci-system cert-manager --ignore-not-found
oc get ociclusterautoscalers.capi.openshift.io -A 2>/dev/null || true
oc get crd | grep -E 'ociclusterautoscalers\.capi\.openshift\.io|clusterclasses\.cluster\.x-k8s\.io|machinedeployments\.cluster\.x-k8s\.io|machinesets\.cluster\.x-k8s\.io|machines\.cluster\.x-k8s\.io|ocimachines\.infrastructure\.cluster\.x-k8s\.io|ociclusters\.infrastructure\.cluster\.x-k8s\.io|cert-manager\.io|acme\.cert-manager\.io' || true
oc get clusterrole,clusterrolebinding | grep -E 'oci-capi|capi-|capoci|cert-manager|oci-cluster-autoscaler' || true
oc get role,rolebinding -n kube-system | grep -E 'cert-manager.*leaderelection' || true
oc get scc | grep -E 'oci-capi' || true
oc get deployment -A | grep -E 'oci-capi|capi-manager|capoci|oci-cluster-autoscaler|cert-manager' || true
```

OpenShift-owned CRDs such as `ipaddressclaims.ipam.cluster.x-k8s.io` or unrelated platform CRDs such as `metal3remediations.infrastructure.cluster.x-k8s.io` may still exist and are not owned by this cleanup target. The OpenShift-owned `openshift-machine-api/cluster-autoscaler-operator` deployment is also expected to remain.
