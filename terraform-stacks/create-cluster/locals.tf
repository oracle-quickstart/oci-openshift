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

  apps_subnet_id        = var.enable_public_apps_lb ? module.network.op_subnet_public : module.network.op_subnet_private_ocp
  apps_security_list_id = var.enable_public_apps_lb ? module.network.op_security_list_public : module.network.op_security_list_private

  # how long resource creation will be paused to allow for newly created tagging resources to reach consistency
  wait_for_new_tag_consistency_wait_time = "900s"
}
