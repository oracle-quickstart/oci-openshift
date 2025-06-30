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

output "etc_hosts_entry" {
  value = <<EOT
${module.load_balancer.op_lb_openshift_api_lb_ip_addr}  api.${var.cluster_name}.${var.zone_dns}
${module.load_balancer.op_lb_openshift_apps_lb_ip_addr}  console-openshift-console.apps.${var.cluster_name}.${var.zone_dns} oauth-openshift.apps.${var.cluster_name}.${var.zone_dns}
EOT
}

output "stack_version" {
  value = local.stack_version
}
