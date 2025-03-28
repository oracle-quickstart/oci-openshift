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

  tag_namespace = [for key, value in data.oci_core_vcns.cluster_vcn.virtual_networks[0].defined_tags : trimsuffix(key, ".openshift-resource") if value == format("openshift-resource-%s", var.cluster_name)][0]
}
