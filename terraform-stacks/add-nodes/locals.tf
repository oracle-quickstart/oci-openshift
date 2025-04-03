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

  current_cp_count      = length(data.oci_load_balancer_backends.openshift_api_apps_api_backend.backends)
  current_compute_count = length(data.oci_load_balancer_backends.openshift_api_apps_ingress_http.backends) - local.current_cp_count

  day_2_image_name = format("%s-day-2", var.cluster_name)

  cluster_instance_role_tag_namespace = var.cluster_instance_role_tag_namespace != "" ? var.cluster_instance_role_tag_namespace : format("openshift-%s", var.cluster_name)
}
