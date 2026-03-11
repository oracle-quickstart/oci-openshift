
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
    ${file("${path.module}/oci-ccm-csi-drivers/${var.oci_driver_version}/01-oci-ccm.yml")}
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

output "autoscaling_manifest" {
  description = "Autoscaling operator manifests to apply after cluster installation has converged."
  value       = var.use_autoscaling_operator ? local.autoscaling_operator_runtime_bundle : null

  precondition {
    condition     = !var.use_autoscaling_operator || var.autoscalar_node_maximum_count >= var.autoscalar_node_minimum_count
    error_message = "The autoscalar_node_maximum_count value must be greater than or equal to autoscalar_node_minimum_count."
  }
}

output "agent_config" {
  value = local.agent_config
}

output "install_config" {
  value = local.install_config
}
