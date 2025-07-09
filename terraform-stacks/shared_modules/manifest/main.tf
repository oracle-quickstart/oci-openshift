
terraform {
  required_version = ">= 1.0"
}

output "oci_ccm_config" {
  description = "Contains resource OCIDs of OCI cluster resources for use by OCI Cloud Controller Manager and Cloud Storage Interface. This block is to be copied to the OCI and CCM manifest files before use during cluster installation."
  value       = local.common_config
}

output "dynamic_custom_manifest" {
  description = "The custom manifests to be applied during OpenShift cluster installation process."
  value       = <<-EOT
    ${file("${path.module}/oci-ccm-csi-drivers/${var.oci_driver_version}/01-oci-ccm.yml")}
    ${file("${path.module}/oci-ccm-csi-drivers/${var.oci_driver_version}/01-oci-csi.yml")}
    ${local.oci_ccm_config_secret}
    ${local.oci_csi_config_secret}
    ${file("${path.module}/manifests/02-machineconfig-ccm.yml")}
    ${file("${path.module}/manifests/02-machineconfig-csi.yml")}
    ${file("${path.module}/manifests/03-machineconfig-consistent-device-path.yml")}
    ${file("${path.module}/manifests/04-cluster-network.yml")}
    ${file("${path.module}/manifests/05-oci-eval-user-data.yml")}
  EOT
}

output "agent_config" {
  value = local.agent_config
}

output "install_config" {
  value = local.install_config
}
