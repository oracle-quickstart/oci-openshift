output "op_vcn_openshift_vcn" {
  value = try(oci_core_vcn.openshift_vcn.id, null)
}

output "op_subnet_private_opc" {
  value = try(oci_core_subnet.private_opc.id, null)
}

output "op_subnet_private_bare_metal" {
  value = try(oci_core_subnet.private_bare_metal.id, null)
}

output "op_subnet_public" {
  value = try(oci_core_subnet.public.id, null)
}

output "op_network_security_group_cluster_lb_nsg" {
  value = try(oci_core_network_security_group.cluster_lb_nsg.id, null)
}

output "op_network_security_group_cluster_controlplane_nsg" {
  value = try(oci_core_network_security_group.cluster_controlplane_nsg.id, null)
}

output "op_network_security_group_cluster_compute_nsg" {
  value = try(oci_core_network_security_group.cluster_compute_nsg.id, null)
}

output "op_security_list_private" {
  value = try(oci_core_security_list.private.id, null)
}

output "op_security_list_public" {
  value = try(oci_core_security_list.public.id, null)
}

output "op_wait_for_vcn_creation" {
  value = time_sleep.wait_for_vcn_creation
}
