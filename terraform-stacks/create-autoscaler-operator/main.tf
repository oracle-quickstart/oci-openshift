terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

provider "oci" {
  region = var.region
}

data "oci_core_subnet" "existing_private_ocp" {
  subnet_id = var.existing_private_ocp_subnet_id
}

data "oci_core_subnet" "existing_private_bare_metal" {
  count = var.bare_metal_subnet_id == "" ? 0 : 1

  subnet_id = var.bare_metal_subnet_id
}

module "discovery" {
  source                         = "./shared_modules/discovery/autoscaling"
  compartment_ocid               = var.compartment_ocid
  cluster_name                   = var.cluster_name
  existing_vcn_id                = var.existing_vcn_id
  existing_private_ocp_subnet_id = var.existing_private_ocp_subnet_id
  networking_compartment_ocid    = var.networking_compartment_ocid
}

module "image" {
  source = "./shared_modules/image"

  compartment_ocid            = var.compartment_ocid
  create_openshift_instances  = false
  image_name                  = "${var.cluster_name}-autoscaling"
  is_control_plane_iscsi_type = false
  is_compute_iscsi_type       = false
  openshift_image_source_uri  = ""
  control_plane_shape         = var.autoscaler_node_shape
  compute_shape               = var.autoscaler_node_shape

  use_autoscaling_operator         = true
  autoscaler_node_image_source_uri = var.autoscaler_node_image_source_uri
  autoscaler_node_shape            = var.autoscaler_node_shape

  # No defined_tags to avoid home-region provider requirement here
  defined_tags = {}
}

module "autoscaling_manifest" {
  source = "./shared_modules/manifest/autoscaling"

  compartment_ocid                         = var.compartment_ocid
  region                                   = var.region
  tenancy_ocid                             = var.tenancy_ocid
  op_vcn_id                                = module.discovery.vcn_id
  op_subnet_private_ocp                    = module.discovery.subnet_private_ocp_id
  op_network_security_group_cluster_lb_nsg = module.discovery.lb_nsg_id
  op_lb_openshift_api_lb                   = module.discovery.api_lb_id
  op_lb_openshift_api_lb_ip_addr           = module.discovery.api_lb_ip_addr

  autoscaler_node_shape             = var.autoscaler_node_shape
  autoscaler_node_minimum_count     = var.autoscaler_node_minimum_count
  autoscaler_node_maximum_count     = var.autoscaler_node_maximum_count
  autoscaler_node_ocpus             = var.autoscaler_node_ocpus
  autoscaler_node_memory            = var.autoscaler_node_memory
  cluster_network_cidr_block        = var.cluster_network_cidr_block
  service_network_cidr_block        = var.service_network_cidr_block
  autoscaler_defined_tags_namespace = var.autoscaler_defined_tags_namespace
  bare_metal_subnet_id              = var.bare_metal_subnet_id
  bare_metal_subnet_name            = try(data.oci_core_subnet.existing_private_bare_metal[0].display_name, "")
  ocp_subnet_name                   = data.oci_core_subnet.existing_private_ocp.display_name
  autoscaler_node_image_id          = module.image.op_image_openshift_autoscaling_image
}
