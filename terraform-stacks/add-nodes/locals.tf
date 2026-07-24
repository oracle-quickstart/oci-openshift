data "oci_identity_regions" "regions" {
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  }

  home_region = local.region_map[data.oci_identity_tenancy.tenancy.home_region_key]

  is_control_plane_iscsi_type = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type       = can(regex("^BM\\..*$", var.compute_shape))

  lb_current_cp_count      = length(data.oci_load_balancer_backends.openshift_api_backend.backends)
  lb_current_compute_count = max(length(data.oci_load_balancer_backends.openshift_apps_ingress_http.backends) - local.lb_current_cp_count, 0)

  existing_cp_indexes = [
    for instance in data.oci_core_instances.cluster_nodes.instances :
    tonumber(regex(format("^%s-cp-([0-9]+)$", var.cluster_name), instance.display_name)[0])
    if length(regexall(format("^%s-cp-[0-9]+$", var.cluster_name), instance.display_name)) > 0
  ]

  existing_compute_indexes = [
    for instance in data.oci_core_instances.cluster_nodes.instances :
    tonumber(regex(format("^%s-compute-([0-9]+)$", var.cluster_name), instance.display_name)[0])
    if length(regexall(format("^%s-compute-[0-9]+$", var.cluster_name), instance.display_name)) > 0
  ]

  current_cp_count      = max(concat([local.lb_current_cp_count], local.existing_cp_indexes)...)
  current_compute_count = max(concat([local.lb_current_compute_count], local.existing_compute_indexes)...)

  existing_node_display_names = toset([
    for instance in data.oci_core_instances.cluster_nodes.instances :
    instance.display_name
  ])

  planned_cp_display_names = toset([
    for _, node in module.meta.cp_node_map :
    format("%s-cp-%s", var.cluster_name, node.index)
  ])

  planned_compute_display_names = toset([
    for _, node in module.meta.compute_node_map :
    format("%s-compute-%s", var.cluster_name, node.index)
  ])

  conflicting_cp_display_names      = setintersection(local.planned_cp_display_names, local.existing_node_display_names)
  conflicting_compute_display_names = setintersection(local.planned_compute_display_names, local.existing_node_display_names)

  day_2_image_name = format("%s-day-2", var.cluster_name)

  cluster_instance_role_tag_namespace = var.cluster_instance_role_tag_namespace != "" ? var.cluster_instance_role_tag_namespace : format("openshift-%s", var.cluster_name)
}
