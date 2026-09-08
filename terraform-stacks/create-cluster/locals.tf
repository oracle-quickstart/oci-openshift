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

  current_region_key = [
    for r in data.oci_identity_regions.regions.regions :
    r.key if r.name == var.region
  ][0]

  home_region = local.region_map[data.oci_identity_tenancy.tenancy.home_region_key]

  is_control_plane_iscsi_type = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type       = can(regex("^BM\\..*$", var.compute_shape))
  is_autoscaler_bm_shape      = can(regex("^BM\\..*$", var.autoscaler_node_shape))
  effective_compute_count     = var.use_autoscaling_operator ? 0 : var.compute_count

  apps_subnet_id                   = var.enable_public_apps_lb ? module.network.op_subnet_public : module.network.op_subnet_private_ocp
  apps_security_list_id            = var.enable_public_apps_lb ? module.network.op_security_list_public : module.network.op_security_list_private
  existing_vcn_compartment_ocid    = var.use_existing_network ? var.vcn_compartment_ocid : null
  existing_subnet_compartment_ocid = var.use_existing_network ? var.subnet_compartment_ocid : null

  openshift_installer_version = var.set_openshift_installer_version ? var.openshift_installer_version : "latest"

  # Derive the OCI realm domain from the tenancy OCID.
  # OCID format: ocid1.<resource>.<realm>.<region>.<unique_id>
  realm_id = split(".", var.tenancy_ocid)[2]
  realm_domain_map = {
    "oc1"  = "oraclecloud.com"
    "oc2"  = "oraclegovcloud.com"
    "oc3"  = "oraclegovcloud.com"
    "oc4"  = "oraclegovcloud.uk"
    "oc5"  = "oraclecloud5.com"
    "oc8"  = "oraclecloud8.com"
    "oc9"  = "oraclecloud9.com"
    "oc10" = "oraclecloud10.com"
    "oc14" = "oraclecloud14.com"
    "oc19" = "oraclecloud19.com"
    "oc20" = "oraclecloud20.com"
    "oc21" = "oraclecloud21.com"
    "oc24" = "oraclecloud24.com"
    "oc26" = "oraclecloud26.com"
  }
  derived_realm_domain = lookup(local.realm_domain_map, local.realm_id, "oraclecloud.com")
  realm_domain = var.realm_domain_component != "" ? var.realm_domain_component : local.derived_realm_domain

  # how long resource creation will be paused to allow for newly created tagging resources to reach consistency
  wait_for_new_tag_consistency_wait_time = "30s"
}
