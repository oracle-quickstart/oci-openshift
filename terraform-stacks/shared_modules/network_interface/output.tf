output "op_vcn_openshift_vcn" {
  value = var.use_existing_network ? module.network_validator[0].vcn_details.vcn_id : module.network[0].op_vcn_openshift_vcn
}

output "op_subnet_private_ocp" {
  value = var.use_existing_network ? module.network_validator[0].subnet_details.private_ocp_subnet.id : module.network[0].op_subnet_private_ocp
}

output "op_subnet_private_bare_metal" {
  value = var.use_existing_network ? module.network_validator[0].subnet_details.private_bare_metal_subnet.id : module.network[0].op_subnet_private_bare_metal
}

output "op_subnet_public" {
  value = var.use_existing_network ? module.network_validator[0].subnet_details.public_subnet.id : module.network[0].op_subnet_public
}

output "op_network_security_group_cluster_lb_nsg" {
  value = var.use_existing_network ? module.network_validator[0].nsg_details.lb_nsg.id : module.network[0].op_network_security_group_cluster_lb_nsg
}

output "op_network_security_group_cluster_controlplane_nsg" {
  value = var.use_existing_network ? module.network_validator[0].nsg_details.controlplane_nsg.id : module.network[0].op_network_security_group_cluster_controlplane_nsg
}

output "op_network_security_group_cluster_compute_nsg" {
  value = var.use_existing_network ? module.network_validator[0].nsg_details.compute_nsg.id : module.network[0].op_network_security_group_cluster_compute_nsg
}

output "op_security_list_private" {
  value = var.use_existing_network ? module.network_validator[0].security_list_details.private_security_list.id : module.network[0].op_security_list_private
}

output "op_security_list_public" {
  value = var.use_existing_network ? module.network_validator[0].security_list_details.public_security_list.id : module.network[0].op_security_list_public
}

output "op_wait_for_vcn_creation" {
  value = var.use_existing_network ? null : module.network[0].op_wait_for_vcn_creation
}
