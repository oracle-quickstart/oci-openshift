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
**04-cluster-network.yml** | Cluster resource that configures the default Network's internalMasqueradeSubnet to 169.254.64.0/18 to avoid collisions with iSCSI boot volumes. |Required when using Bare Metal instances with OpenShift versions >= 4.17
**05-oci-eval-user-data.yml** | MachineConfig that evaluates and runs [userdata scripts](/terraform-stacks/shared_modules/compute/userdata/) stored in the metadata of instances. | Required when using Bare Metal instances
**06-oci-oca.yml** | Cluster resources for Oracle Cloud Agent on OpenShift nodes. See [oracle-cloud-agent.md](/docs/oracle-cloud-agent.md). | Optional
**07-configure-bm-vlan-mtu.yml** | MachineConfig that configures MTU 9000 on VLAN-backed bare metal interfaces. | Required when using Bare Metal instances with VLAN-backed networking
**08-autoscaling-operator.yml** | Bootstrap manifest for the OCI OpenShift Autoscaler operator namespace, activation job, and initial operator install flow. | Required when enabling OCI OpenShift Autoscaler
**09-autoscaling-operator-runtime.yml** | Runtime manifest applied by the autoscaler activation job to install the OCI CAPI operator controller, RBAC, CRD, and provider installer resources. | Required when enabling OCI OpenShift Autoscaler
**10-autoscaling-operator-configs.yml** | Configuration template for autoscaler operator, CAPI, CAPOCI, Cluster Autoscaler, OCI networking, image, and node-pool settings. | Required when enabling OCI OpenShift Autoscaler

Previously, the `oci_ccm_config` output from the OCI Resource Manager Stack (RMS) job was used to replace configuration values in `manifests/01-oci-ccm.yml` and `manifests/01-oci-csi.yml`, and then all required manifests were uploaded individually during cluster creation. This workflow is still valid, but the configuration values to be replaced are now located in [manifests/01-oci-driver-configs.yml](./manifests/01-oci-driver-configs.yml).

### Individual Manifest Outputs (Agent-based Installer)
---
The `create-cluster` stack provides individual terraform outputs for each manifest, suitable for the agent-based installer's `openshift/` directory (which requires one manifest per file). Write them to disk with:

```bash
mkdir -p openshift
for m in manifest_oci_ccm manifest_oci_csi manifest_oci_ccm_config manifest_oci_csi_config \
         manifest_machineconfig_ccm manifest_machineconfig_csi manifest_machineconfig_device_path \
         manifest_cluster_network manifest_machineconfig_eval_user_data manifest_machineconfig_bm_vlan_mtu; do
  terraform output -raw "$m" > "openshift/${m}.yaml"
done
```

| Output | Contents |
| --- | --- |
| `manifest_oci_ccm` | OCI Cloud Controller Manager (Namespace, SA, ClusterRole, ClusterRoleBinding, DaemonSet) |
| `manifest_oci_csi` | OCI CSI driver resources |
| `manifest_oci_ccm_config` | CCM cloud-provider config Secret |
| `manifest_oci_csi_config` | CSI volume-provisioner config Secret |
| `manifest_machineconfig_ccm` | MachineConfig for CCM provider-id |
| `manifest_machineconfig_csi` | MachineConfig for iscsid service |
| `manifest_machineconfig_device_path` | MachineConfig for consistent device paths |
| `manifest_cluster_network` | Network operator config (internalMasqueradeSubnet) |
| `manifest_machineconfig_eval_user_data` | MachineConfig for OCI eval user-data |
| `manifest_machineconfig_bm_vlan_mtu` | MachineConfig for bare metal VLAN MTU |
| `manifest_oca` | Oracle Cloud Agent (null when `use_oracle_cloud_agent = false`) |
| `manifest_autoscaler_operator` | Autoscaler operator bootstrap (null when `use_autoscaling_operator = false`) |
| `manifest_autoscaler_runtime_configmap` | Autoscaler runtime manifest ConfigMap (null when `use_autoscaling_operator = false`) |

### Dynamic Custom Manifest Output (legacy)
---
The `dynamic_custom_manifest` output is still available for backward compatibility. It contains all required manifests concatenated into a single multi-document YAML string. This format works with the Assisted Installer and `oc apply -f` but is **not compatible** with the agent-based installer's `openshift/` directory, which requires individual files.

### Autoscaler Manifest Output
---
The OCI OpenShift Autoscaler manifests are generated by the `create-cluster` stack for Day 0 enablement and by the `create-autoscaler-operator` stack for Day 1 enablement. These manifests are emitted through the `autoscaling_manifest` output and include the autoscaler operator bootstrap, runtime resources, configuration, and `OCIClusterAutoscaler` custom resource.

For installation, verification, scale up/down, monitoring, troubleshooting, and cleanup steps, see the [OCI OpenShift Autoscaler Guide](/docs/AUTOSCALER.md).
