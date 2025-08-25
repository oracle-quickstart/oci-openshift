
# backends for openshift nodes

resource "oci_load_balancer_backend" "openshift_cluster_api_backend_set_external_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_api_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_api_backend_set_external
  port             = 6443
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cp_cluster_ingress_https_backend_set_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_apps_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_ingress_https_backend_set
  port             = 443
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cp_cluster_ingress_http_backend_set_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_apps_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_ingress_http_backend_set
  port             = 80
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_api_backend_set_internal_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_api_int_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_api_backend_set_internal
  port             = 6443
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_infra-mcs_backend_set_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_api_int_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_infra-mcs_backend_set
  port             = 22623
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_infra-mcs_backend_set_2_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_api_int_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_infra-mcs_backend_set_2
  port             = 22624
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_infra-mcs_backend_set_api_2_backends" {
  for_each         = var.create_openshift_instances ? var.cp_node_map : {}
  load_balancer_id = var.op_lb_openshift_api_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_infra-mcs_backend_set_api_2
  port             = 22624
  ip_address       = var.is_control_plane_iscsi_type ? data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_ingress_https_backend_set_backends" {
  for_each         = var.create_openshift_instances ? var.compute_node_map : {}
  load_balancer_id = var.op_lb_openshift_apps_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_ingress_https_backend_set
  port             = 443
  ip_address       = var.is_compute_iscsi_type ? data.oci_core_vnic.compute_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.compute_primary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_ingress_http_backend_set_backends" {
  for_each         = var.create_openshift_instances ? var.compute_node_map : {}
  load_balancer_id = var.op_lb_openshift_apps_lb
  backendset_name  = var.op_lb_bs_openshift_cluster_ingress_http_backend_set
  port             = 80
  ip_address       = var.is_compute_iscsi_type ? data.oci_core_vnic.compute_secondary_vnic[each.key].private_ip_address : data.oci_core_vnic.compute_primary_vnic[each.key].private_ip_address
}
