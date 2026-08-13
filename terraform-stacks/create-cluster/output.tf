output "open_shift_api_int_lb_addr" {
  value = module.load_balancer.op_lb_openshift_api_int_lb_ip_addr
}

output "open_shift_api_lb_addr" {
  value = module.load_balancer.op_lb_openshift_api_lb_ip_addr
}

output "open_shift_apps_lb_addr" {
  value = module.load_balancer.op_lb_openshift_apps_lb_ip_addr
}

output "oci_ccm_config" {
  value = module.manifests.oci_ccm_config
}

output "dynamic_custom_manifest" {
  value = module.manifests.dynamic_custom_manifest
}

output "manifest_oci_ccm" {
  value = module.manifests.manifest_oci_ccm
}

output "manifest_oci_csi" {
  value = module.manifests.manifest_oci_csi
}

output "manifest_oci_ccm_config" {
  value = module.manifests.manifest_oci_ccm_config
}

output "manifest_oci_csi_config" {
  value = module.manifests.manifest_oci_csi_config
}

output "manifest_machineconfig_ccm" {
  value = module.manifests.manifest_machineconfig_ccm
}

output "manifest_machineconfig_csi" {
  value = module.manifests.manifest_machineconfig_csi
}

output "manifest_machineconfig_device_path" {
  value = module.manifests.manifest_machineconfig_device_path
}

output "manifest_cluster_network" {
  value = module.manifests.manifest_cluster_network
}

output "manifest_machineconfig_eval_user_data" {
  value = module.manifests.manifest_machineconfig_eval_user_data
}

output "manifest_machineconfig_bm_vlan_mtu" {
  value = module.manifests.manifest_machineconfig_bm_vlan_mtu
}

output "manifest_oca" {
  value = module.manifests.manifest_oca
}

output "manifest_autoscaler_operator" {
  value = module.manifests.manifest_autoscaler_operator
}

output "manifest_autoscaler_runtime_configmap" {
  value = module.manifests.manifest_autoscaler_runtime_configmap
}

output "autoscaling_manifest" {
  description = "Autoscaling operator manifests for post-install OpenShift clusters."
  value       = module.manifests.autoscaling_manifest
}

output "etc_hosts_entry" {
  value = <<EOT
${module.load_balancer.op_lb_openshift_api_lb_ip_addr}  api.${var.cluster_name}.${var.zone_dns}
${module.load_balancer.op_lb_openshift_apps_lb_ip_addr}  console-openshift-console.apps.${var.cluster_name}.${var.zone_dns} oauth-openshift.apps.${var.cluster_name}.${var.zone_dns}
EOT
}

output "agent_config" {
  value       = var.installation_method == "Assisted" ? null : module.manifests.agent_config
  description = "Agent config output; null if use Assisted Installer."
}

output "install_config" {
  value       = var.installation_method == "Assisted" ? null : module.manifests.install_config
  description = "Install config output; null if use Assisted Installer."
}

output "stack_version" {
  value = local.stack_version
}
