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

  is_control_plane_iscsi_type            = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type                  = can(regex("^BM\\..*$", var.compute_shape))
  openshift_tag_openshift_resource_value = "openshift-resource-${var.cluster_name}"

  subnet_id        = var.enable_private_dns && !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? module.network.op_subnet_private : var.enable_private_dns ? module.network.op_subnet_private2 : module.network.op_subnet_public
  security_list_id = var.enable_private_dns ? module.network.op_security_list_private : module.network.op_security_list_public
}
