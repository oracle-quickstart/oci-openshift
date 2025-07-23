# Custom Manifests

These OpenShift and Kubernetes manifest files support the installation of Red Hat OpenShift clusters on Oracle Cloud Infrastructure. The Butane files used to generate the OpenShift MachineConfigs are also included.

View usage during [installation](/README.md#documentation-and-installation-instructions)


## Individual Manifests
| File | Description | When to Use |
--- | --- | ---
**01-oci-ccm.yml** | Cluster resources for OCI Cloud Controller Manager (CCM). | Always ✅
**01-oci-csi.yml** | Cluster resources for OCI Container Storage Interface (CSI). See [STORAGE.md](~/docs/STORAGE.md) | Always ✅
**01-oci-driver-configs.yml** | Configuration Secrets for CCM and CSI drivers. ❗**Contains placeholder values that need to be replaced before use.** | Always ✅
**02-machineconfig-ccm.yml** | MachineConfig that fetches the provider (OCI) id for kubelet from the OCI metadata of the instance. | Always ✅
**02-machineconfig-csi.yml** | MachineConfig that enables the iscsid.service to run. | Always ✅
**03-machineconfig-consistent-device-path.yml** | MachineConfig that ensures consistent device paths when attaching paravirtualized volumes to instances. | Always ✅
**04-cluster-network.yml** | Cluster resource that configures the default Network's internalMasqueradeSubnet xto 169.254.64.0/18 to avoid collisions with iSCSI boot volumes. |Required when using Bare Metal instances with OpenShift versions >= 4.17
**05-oci-eval-user-data.yml** | MachineConfig that evaluates and runs [userdata scripts](/terraform-stacks/shared_modules/compute/userdata/) stored in the metadata of instances. | Required when using Bare Metal instances

Previously, the `oci_ccm_config` output from the OCI Resource Manager Stack (RMS) job was used to replace configuration values in `manifests/01-oci-ccm.yml` and `manifests/01-oci-csi.yml`, and then all required manifests were uploaded individually during cluster creation. This workflow is still valid, but the configuration values to be replaced are now located in [manifests/01-oci-driver-configs.yml](./manifests/01-oci-driver-configs.yml).

### Dynamic Custom Manifest Output
---
Most of our terraform-stacks have an output called `dynamic_custom_manifest`. This output contains all required manifests, concatenated and pre-formatted with the configuration values for CCM and CSI. This output can be copied and used to create a single manifest file which can then be uploaded during the cluster installation process.
