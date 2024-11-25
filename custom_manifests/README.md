# Custom Manifests

These OpenShift and Kubernetes manifest files support the installation of Red Hat OpenShift clusters on Oracle Cloud Infrastructure. The Butane files used to generate the OpenShift MachineConfigs are also included.

View usage during [installation](/README.md#documentation-and-installation-instructions)


### Individual Manifests
---
| File | Description | When to Use |
--- | --- | ---
**01-oci-ccm.yml** | Cluster resources for OCI Cloud Controller Manager (CCM). | Always ✅
**01-oci-csi.yml** | Cluster resources for OCI Cloud Storage Interface (CSI). See [STORAGE.md](/STORAGE.md) | Always ✅
**01-oci-driver-configs.yml** | Configuration Secrets for CCM and CSI drivers. ❗**Contains placeholder values that need to be replaced before use.** | Always ✅
**02-machineconfig-ccm.yml** | MachineConfig that fetches the provider (OCI) id for kubelet from the OCI Metadata of the instance. | Always ✅
**02-machineconfig-csi.yml** | MachineConfig that enables the iscsid.service to run. | Always ✅
**03-machineconfig-consistent-device-path.yml** | MachineConfig that ensures consistent device paths when attaching paravirtualized volumes to instances. | Always ✅
**04-cluster-network.yml** | Cluster resource that configures the default Network's internalMasqueradeSubnet to 169.254.64.0/18 to avoid collisions with iSCSI boot volumes. |Required when using Bare Metal instances with OpenShift versions >= 4.17
**05-oci-eval-user-data.yml** | MachineConfig that evaluates and runs userdata scripts stored in the metadata of instances. | Required when using Bare Metal instances

Previously, the `oci_ccm_config` output from the OCI Resource Manager Stack (RMS) job was used to replace configuration values in `manifests/01-oci-ccm.yml` and `manifests/01-oci-csi.yml`, and then all required manifests were uploaded individually during cluster creation. This workflow is still valid, but the configuration values to be replaced are now located in [manifests/01-oci-driver-configs.yml](./manifests/01-oci-driver-configs.yml).

### Dynamic Condensed Manifest Output
---
Most of our terraform-stacks have an output called `dynamic_custom_manifest`. This output contains all required manifests, concatenated and pre-formatted with the configuration values for CCM and CSI. This output can be copied and used to create a single manifest file which can then be uploaded during the cluster installation process.

There is also a non-dynamic [condensed-manifest.yml](./condensed-manifest.yml) which contains all manifests (for easier upload), but still requires the sections for CCM and CSI configuration values to be replaced by the RMS job output `oci_ccm_config`, or manually formatted with OCI resource OCID's from your existing cluster infrastructure. These sections have been marked with a `TODO` so they can be easily located and replaced. See oci-cloud-controller-manager [example](https://github.com/oracle/oci-cloud-controller-manager/blob/master/manifests/provider-config-instance-principals-example.yaml) for more information.


### oci-ccm-csi-drivers

TODO - briefly describe the purpose of the files in here
