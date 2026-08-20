
terraform {
  required_version = ">= 1.0"
}

output "oci_ccm_config" {
  description = "Contains resource OCIDs of OCI cluster resources for use by OCI Cloud Controller Manager and Container Storage Interface. This block is to be copied to the OCI and CCM manifest files before use during cluster installation."
  value       = local.common_config
}

output "dynamic_custom_manifest" {
  description = "The custom manifests to be applied during OpenShift cluster installation process."
  value       = <<-EOT
    ${local.oci_ccm}
    ${local.oci_csi}
    ${local.oci_ccm_config_secret}
    ${local.oci_csi_config_secret}
    %{if var.use_oracle_cloud_agent && var.oca_image_pull_link != "" && var.oca_image_pull_link != "no-image-found"}
    ${local.oca_yaml}
    %{endif}
    ${file("${path.module}/manifests/02-machineconfig-ccm.yml")}
    ${file("${path.module}/manifests/02-machineconfig-csi.yml")}
    ${file("${path.module}/manifests/03-machineconfig-consistent-device-path.yml")}
    ${file("${path.module}/manifests/04-cluster-network.yml")}
    ${file("${path.module}/manifests/05-oci-eval-user-data.yml")}
    ${file("${path.module}/manifests/07-configure-bm-vlan-mtu.yml")}
    %{if var.use_autoscaling_operator}
    ${file("${path.module}/manifests/08-autoscaling-operator.yml")}
    ${local.autoscaling_operator_runtime_manifest_configmap}
    %{endif}
  EOT
}

output "manifest_oci_ccm" {
  description = "OCI Cloud Controller Manager resources (Namespace, ServiceAccount, ClusterRole, ClusterRoleBinding, DaemonSet)."
  value       = trimspace(local.oci_ccm)
}

output "manifest_oci_csi" {
  description = "OCI Container Storage Interface driver resources."
  value       = trimspace(local.oci_csi)
}

output "manifest_oci_ccm_config" {
  description = "OCI CCM cloud-provider config Secret."
  value       = trimspace(trimsuffix(trimspace(local.oci_ccm_config_secret), "---"))
}

output "manifest_oci_csi_config" {
  description = "OCI CSI volume-provisioner config Secret."
  value       = trimspace(trimsuffix(trimspace(local.oci_csi_config_secret), "---"))
}

output "manifest_machineconfig_ccm" {
  description = "MachineConfig for OCI CCM."
  value       = trimspace(file("${path.module}/manifests/02-machineconfig-ccm.yml"))
}

output "manifest_machineconfig_csi" {
  description = "MachineConfig for OCI CSI."
  value       = trimspace(file("${path.module}/manifests/02-machineconfig-csi.yml"))
}

output "manifest_machineconfig_device_path" {
  description = "MachineConfig for consistent device paths."
  value       = trimspace(file("${path.module}/manifests/03-machineconfig-consistent-device-path.yml"))
}

output "manifest_cluster_network" {
  description = "Cluster network operator configuration."
  value       = trimspace(file("${path.module}/manifests/04-cluster-network.yml"))
}

output "manifest_machineconfig_eval_user_data" {
  description = "MachineConfig for OCI eval user-data."
  value       = trimspace(file("${path.module}/manifests/05-oci-eval-user-data.yml"))
}

output "manifest_machineconfig_bm_vlan_mtu" {
  description = "MachineConfig for bare metal VLAN MTU configuration."
  value       = trimspace(file("${path.module}/manifests/07-configure-bm-vlan-mtu.yml"))
}

output "manifest_oca" {
  description = "Oracle Cloud Agent resources. Null when use_oracle_cloud_agent is false."
  value       = var.use_oracle_cloud_agent && var.oca_image_pull_link != "" && var.oca_image_pull_link != "no-image-found" ? trimspace(trimsuffix(trimspace(local.oca_yaml), "---")) : null
}

output "manifest_autoscaler_operator" {
  description = "Autoscaler operator install-time resources. Null when use_autoscaling_operator is false."
  value       = var.use_autoscaling_operator ? trimspace(file("${path.module}/manifests/08-autoscaling-operator.yml")) : null
}

output "manifest_autoscaler_runtime_configmap" {
  description = "Autoscaler operator runtime manifest ConfigMap. Null when use_autoscaling_operator is false."
  value       = var.use_autoscaling_operator ? trimspace(local.autoscaling_operator_runtime_manifest_configmap) : null
}

output "autoscaling_manifest" {
  description = "Autoscaling operator manifests to apply after cluster installation has converged."
  value       = var.use_autoscaling_operator ? local.autoscaling_operator_runtime_bundle : null

  precondition {
    condition     = !var.use_autoscaling_operator || var.autoscaler_node_maximum_count >= var.autoscaler_node_minimum_count
    error_message = "The autoscaler_node_maximum_count value must be greater than or equal to autoscaler_node_minimum_count."
  }

  precondition {
    condition     = !var.use_autoscaling_operator || length(var.cluster_name) + 6 + (var.autoscaler_pool_identifier == "" ? 0 : 1 + length(var.autoscaler_pool_identifier)) <= 51
    error_message = "The generated autoscaler node pool name must be no longer than 51 characters. Shorten cluster_name or autoscaler_pool_identifier."
  }
}

output "agent_config" {
  value = local.agent_config
}

output "install_config" {
  value = local.install_config
}
