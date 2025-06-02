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

output "stack_version" {
  value = local.stack_version
}
