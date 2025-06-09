terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.1"
    }
  }
}

provider "oci" {
  alias  = "home"
  region = local.home_region
}

module "tags" {
  source = "./shared_modules/tags"

  providers = {
    oci = oci.home
  }

  use_existing_tags                      = true
  compartment_ocid                       = var.compartment_ocid
  tag_namespace_compartment_ocid         = data.oci_identity_tag_namespaces.openshift_tag_namespace.tag_namespaces[0].compartment_id
  tag_namespace_name                     = local.cluster_instance_role_tag_namespace
  cluster_name                           = var.cluster_name
  wait_for_new_tag_consistency_wait_time = "5s"
}

module "image" {
  source = "./shared_modules/image"

  depends_on = [module.tags.wait_for_tag_consistency]

  compartment_ocid            = var.compartment_ocid
  create_openshift_instances  = true
  image_name                  = local.day_2_image_name
  is_control_plane_iscsi_type = local.is_control_plane_iscsi_type
  is_compute_iscsi_type       = local.is_compute_iscsi_type
  openshift_image_source_uri  = var.openshift_image_source_uri
  control_plane_shape         = var.control_plane_shape
  compute_shape               = var.compute_shape

  // Depedency on tags
  defined_tags = module.resource_attribution_tags.openshift_resource_attribution_tag
}
module "meta" {
  source                                  = "./shared_modules/meta"
  compartment_ocid                        = var.compartment_ocid
  control_plane_count                     = var.control_plane_count
  compute_count                           = var.compute_count
  starting_ad_name_cp                     = var.starting_ad_name_cp
  starting_ad_name_compute                = var.starting_ad_name_compute
  distribute_cp_instances_across_ads      = var.distribute_cp_instances_across_ads
  distribute_compute_instances_across_ads = var.distribute_compute_instances_across_ads
  current_cp_count                        = local.current_cp_count
  current_compute_count                   = local.current_compute_count
}

module "compute" {
  source = "./shared_modules/compute"

  compartment_ocid            = var.compartment_ocid
  cluster_name                = var.cluster_name
  is_control_plane_iscsi_type = local.is_control_plane_iscsi_type
  is_compute_iscsi_type       = local.is_compute_iscsi_type
  create_openshift_instances  = true

  control_plane_shape                   = var.control_plane_shape
  control_plane_boot_size               = var.control_plane_boot_size
  control_plane_boot_volume_vpus_per_gb = var.control_plane_boot_volume_vpus_per_gb
  control_plane_memory                  = var.control_plane_memory
  control_plane_ocpu                    = var.control_plane_ocpu

  compute_shape                   = var.compute_shape
  compute_boot_size               = var.compute_boot_size
  compute_boot_volume_vpus_per_gb = var.compute_boot_volume_vpus_per_gb
  compute_memory                  = var.compute_memory
  compute_ocpu                    = var.compute_ocpu

  // Dependency on AD placement
  cp_node_map      = module.meta.cp_node_map
  compute_node_map = module.meta.compute_node_map

  // Depedency on tags
  op_openshift_tag_boot_volume_type = module.tags.op_openshift_tag_boot_volume_type
  op_openshift_tag_namespace        = module.tags.op_openshift_tag_namespace
  op_openshift_tag_instance_role    = module.tags.op_openshift_tag_instance_role

  // Depedency on image
  op_image_openshift_image_paravirtualized = module.image.op_image_openshift_image_paravirtualized
  op_image_openshift_image_native          = module.image.op_image_openshift_image_native

  // Depedency on networks
  op_subnet_private_opc                              = data.oci_core_subnets.private_opc.subnets[0].id
  op_subnet_private_bare_metal                       = data.oci_core_subnets.private_bare_metal.subnets[0].id
  op_network_security_group_cluster_controlplane_nsg = data.oci_core_network_security_groups.cluster_controlplane_nsg.network_security_groups[0].id
  op_network_security_group_cluster_compute_nsg      = data.oci_core_network_security_groups.cluster_compute_nsg.network_security_groups[0].id

  // Depedency on loadbalancer
  op_lb_openshift_api_int_lb                           = data.oci_load_balancer_load_balancers.openshift_api_int_lb.load_balancers[0].id
  op_lb_openshift_api_lb                               = data.oci_load_balancer_load_balancers.openshift_api_lb.load_balancers[0].id
  op_lb_openshift_apps_lb                              = data.oci_load_balancer_load_balancers.openshift_apps_lb.load_balancers[0].id
  op_lb_bs_openshift_cluster_api_backend_set_external  = "openshift_cluster_api_backend"
  op_lb_bs_openshift_cluster_ingress_http_backend_set  = "openshift_cluster_ingress_http"
  op_lb_bs_openshift_cluster_ingress_https_backend_set = "openshift_cluster_ingress_https"
  op_lb_bs_openshift_cluster_api_backend_set_internal  = "openshift_cluster_api_backend"
  op_lb_bs_openshift_cluster_infra-mcs_backend_set     = "openshift_cluster_infra-mcs"
  op_lb_bs_openshift_cluster_infra-mcs_backend_set_2   = "openshift_cluster_infra-mcs_2"
}

module "resource_attribution_tags" {
  source = "./shared_modules/resource_attribution_tags/find_resource_tags"

  providers = {
    oci = oci.home
  }
  tag_namespace_compartment_ocid_resource_tagging = var.tag_namespace_compartment_ocid_resource_tagging
}
