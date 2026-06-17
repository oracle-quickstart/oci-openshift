output "vcn_id" {
  value = data.oci_core_vcn.existing_vcn.id
}

output "subnet_private_ocp_id" {
  value = data.oci_core_subnet.existing_private_ocp.id
}

output "lb_nsg_id" {
  value = try(data.oci_core_network_security_groups.existing_lb_nsgs.network_security_groups[0].id, null)
}

output "api_lb_id" {
  value = try(data.oci_load_balancer_load_balancers.openshift_api_lb.load_balancers[0].id, null)
}

output "api_lb_ip_addr" {
  value = try(data.oci_load_balancer_load_balancers.openshift_api_lb.load_balancers[0].ip_addresses[0], null)
}
