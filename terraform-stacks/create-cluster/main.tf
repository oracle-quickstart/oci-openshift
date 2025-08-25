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

# Home Region Terraform Provider
provider "oci" {
  alias  = "home"
  region = local.home_region
}

module "meta" {
  source                                  = "./shared_modules/meta"
  compartment_ocid                        = var.compartment_ocid
  starting_ad_name_cp                     = var.starting_ad_name_cp
  starting_ad_name_compute                = var.starting_ad_name_compute
  distribute_cp_instances_across_ads      = var.distribute_cp_instances_across_ads
  distribute_compute_instances_across_ads = var.distribute_compute_instances_across_ads
  control_plane_count                     = var.control_plane_count
  compute_count                           = var.compute_count
}
module "tags" {
  source = "./shared_modules/tags"

  providers = {
    oci = oci.home
  }

  use_existing_tags                      = var.use_existing_tags
  compartment_ocid                       = var.compartment_ocid
  tag_namespace_compartment_ocid         = var.tag_namespace_compartment_ocid
  tag_namespace_name                     = var.tag_namespace_name
  cluster_name                           = var.cluster_name
  wait_for_new_tag_consistency_wait_time = local.wait_for_new_tag_consistency_wait_time
}

module "iam" {
  source = "./shared_modules/iam"

  providers = {
    oci = oci.home
  }

  depends_on = [module.tags.wait_for_tag_consistency]

  compartment_ocid            = var.compartment_ocid
  tenancy_ocid                = var.tenancy_ocid
  cluster_name                = var.cluster_name
  networking_compartment_ocid = local.existing_networking_compartment_ocid

  // dependency on tags
  op_openshift_tag_namespace     = module.tags.op_openshift_tag_namespace
  op_openshift_tag_instance_role = module.tags.op_openshift_tag_instance_role
  defined_tags                   = module.resource_attribution_tags.openshift_resource_attribution_tag
}


module "image" {
  source = "./shared_modules/image"

  depends_on = [module.tags.wait_for_tag_consistency]

  compartment_ocid            = var.compartment_ocid
  create_openshift_instances  = var.create_openshift_instances
  image_name                  = var.cluster_name
  is_control_plane_iscsi_type = local.is_control_plane_iscsi_type
  is_compute_iscsi_type       = local.is_compute_iscsi_type
  openshift_image_source_uri  = var.openshift_image_source_uri
  control_plane_shape         = var.control_plane_shape
  compute_shape               = var.compute_shape

  // Depedency on tags
  defined_tags = module.resource_attribution_tags.openshift_resource_attribution_tag
}

module "network" {
  source = "./shared_modules/network_interface"

  depends_on = [module.tags.wait_for_tag_consistency]

  compartment_ocid = var.compartment_ocid
  cluster_name     = var.cluster_name

  # Parameters for creation of new network infrastructure
  vcn_cidr                = var.vcn_cidr
  private_cidr_ocp        = var.private_cidr_ocp
  private_cidr_bare_metal = var.private_cidr_bare_metal
  public_cidr             = var.public_cidr
  vcn_dns_label           = var.vcn_dns_label

  # Parameters to use when using an exisiting network infrastructure
  use_existing_network                  = var.use_existing_network
  networking_compartment_ocid           = var.networking_compartment_ocid
  existing_vcn_id                       = var.existing_vcn_id
  existing_public_subnet_id             = var.existing_public_subnet_id
  existing_private_bare_metal_subnet_id = var.existing_private_bare_metal_subnet_id
  existing_private_ocp_subnet_id        = var.existing_private_ocp_subnet_id

  // Depedency on tags
  defined_tags = module.resource_attribution_tags.openshift_resource_attribution_tag
}

module "load_balancer" {
  source = "./shared_modules/lb"

  compartment_ocid = var.compartment_ocid
  cluster_name     = var.cluster_name

  enable_public_api_lb  = var.enable_public_api_lb
  enable_public_apps_lb = var.enable_public_apps_lb

  load_balancer_shape_details_maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
  load_balancer_shape_details_minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps

  // Depedency on tags
  defined_tags = module.resource_attribution_tags.openshift_resource_attribution_tag

  // Depedency on networks
  op_subnet_private_ocp                    = module.network.op_subnet_private_ocp
  op_subnet_public                         = module.network.op_subnet_public
  op_network_security_group_cluster_lb_nsg = module.network.op_network_security_group_cluster_lb_nsg
}

## Web Server for creating OCP install images and hosting rootfs and ignition files
module "webserver" {
  count  = var.is_disconnected_installation ? 1 : 0
  source = "./shared_modules/webserver"

  is_disconnected_installation = var.is_disconnected_installation
  set_proxy                    = var.set_proxy
  http_proxy                   = var.http_proxy
  https_proxy                  = var.https_proxy
  no_proxy                     = var.no_proxy

  webserver_availability_domain = module.meta.ad_name
  webserver_compartment_ocid    = var.compartment_ocid
  webserver_shape               = var.webserver_shape
  webserver_image_source_id     = var.webserver_image_source_id
  webserver_display_name        = "${var.cluster_name}-webserver"
  webserver_private_ip          = var.webserver_private_ip
  webserver_assign_public_ip    = true # variable
  webserver_memory_in_gbs       = var.webserver_memory_in_gbs
  webserver_ocpus               = var.webserver_ocpus
  public_ssh_key                = var.public_ssh_key
  openshift_installer_version   = local.openshift_installer_version
  cluster_name                  = var.cluster_name
  object_storage_namespace      = var.object_storage_namespace
  object_storage_bucket         = var.object_storage_bucket
  agent_config                  = module.manifests.agent_config
  install_config                = module.manifests.install_config
  dynamic_custom_manifest       = module.manifests.dynamic_custom_manifest

  // Depedency on tags
  openshift_tag_namespace     = module.tags.op_openshift_tag_namespace
  openshift_tag_instance_role = module.tags.op_openshift_tag_instance_role

  // Dependency on networks
  webserver_subnet_id = module.network.op_subnet_public # depend on variable
}

module "compute" {
  source = "./shared_modules/compute"

  compartment_ocid            = var.compartment_ocid
  cluster_name                = var.cluster_name
  is_control_plane_iscsi_type = local.is_control_plane_iscsi_type
  is_compute_iscsi_type       = local.is_compute_iscsi_type
  create_openshift_instances  = var.create_openshift_instances

  rendezvous_ip       = var.rendezvous_ip
  installation_method = var.installation_method

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

  distribute_cp_instances_across_fds      = var.distribute_cp_instances_across_fds
  distribute_compute_instances_across_fds = var.distribute_compute_instances_across_fds

  // Dependency on AD placement
  cp_node_map      = module.meta.cp_node_map
  compute_node_map = module.meta.compute_node_map

  // Depedency on tags
  op_openshift_tag_boot_volume_type = module.tags.op_openshift_tag_boot_volume_type
  op_openshift_tag_namespace        = module.tags.op_openshift_tag_namespace
  op_openshift_tag_instance_role    = module.tags.op_openshift_tag_instance_role

  // Depedency on image
  op_image_openshift_image_native          = module.image.op_image_openshift_image_native
  op_image_openshift_image_paravirtualized = module.image.op_image_openshift_image_paravirtualized

  // Depedency on networks
  op_subnet_private_ocp                              = module.network.op_subnet_private_ocp
  op_subnet_private_bare_metal                       = module.network.op_subnet_private_bare_metal
  op_network_security_group_cluster_controlplane_nsg = module.network.op_network_security_group_cluster_controlplane_nsg
  op_network_security_group_cluster_compute_nsg      = module.network.op_network_security_group_cluster_compute_nsg

  // Depedency on loadbalancer
  op_lb_openshift_api_int_lb                             = module.load_balancer.op_lb_openshift_api_int_lb
  op_lb_openshift_api_lb                                 = module.load_balancer.op_lb_openshift_api_lb
  op_lb_openshift_apps_lb                                = module.load_balancer.op_lb_openshift_apps_lb
  op_lb_bs_openshift_cluster_api_backend_set_external    = module.load_balancer.op_lb_bs_openshift_cluster_api_backend_set_external
  op_lb_bs_openshift_cluster_ingress_http_backend_set    = module.load_balancer.op_lb_bs_openshift_cluster_ingress_http_backend_set
  op_lb_bs_openshift_cluster_ingress_https_backend_set   = module.load_balancer.op_lb_bs_openshift_cluster_ingress_https_backend_set
  op_lb_bs_openshift_cluster_api_backend_set_internal    = module.load_balancer.op_lb_bs_openshift_cluster_api_backend_set_internal
  op_lb_bs_openshift_cluster_infra-mcs_backend_set       = module.load_balancer.op_lb_bs_openshift_cluster_infra-mcs_backend_set
  op_lb_bs_openshift_cluster_infra-mcs_backend_set_2     = module.load_balancer.op_lb_bs_openshift_cluster_infra-mcs_backend_set_2
  op_lb_bs_openshift_cluster_infra-mcs_backend_set_api_2 = module.load_balancer.op_lb_bs_openshift_cluster_infra-mcs_backend_set_api_2
}

module "dns" {
  source = "./shared_modules/dns"

  depends_on = [module.network.op_wait_for_vcn_creation]

  zone_dns           = var.zone_dns
  create_public_dns  = var.create_public_dns
  create_private_dns = var.create_private_dns
  compartment_ocid   = var.compartment_ocid
  cluster_name       = var.cluster_name

  // Depedency on tags
  defined_tags = module.resource_attribution_tags.openshift_resource_attribution_tag

  // Depedency on load balancer
  op_lb_openshift_api_int_lb_ip_addr = module.load_balancer.op_lb_openshift_api_int_lb_ip_addr
  op_lb_openshift_api_lb_ip_addr     = module.load_balancer.op_lb_openshift_api_lb_ip_addr
  op_lb_openshift_apps_lb_ip_addr    = module.load_balancer.op_lb_openshift_apps_lb_ip_addr

  // Depedency on networks
  op_vcn_openshift_vcn = module.network.op_vcn_openshift_vcn
}

module "ocir" {
  source = "./shared_modules/ocir"

  compartment_ocid = var.compartment_ocid
  oca_repo_name    = var.oracle_cloud_agent_repo_name
  region           = local.current_region_key
}

module "manifests" {
  source = "./shared_modules/manifest"

  compartment_ocid   = var.compartment_ocid
  oci_driver_version = var.oci_driver_version

  redhat_pull_secret           = var.redhat_pull_secret
  is_disconnected_installation = var.is_disconnected_installation
  set_proxy                    = var.set_proxy
  http_proxy                   = var.http_proxy
  https_proxy                  = var.https_proxy
  no_proxy                     = var.no_proxy


  // Depedency on networks
  op_vcn_openshift_vcn  = module.network.op_vcn_openshift_vcn
  op_apps_subnet        = local.apps_subnet_id
  op_apps_security_list = "${local.apps_subnet_id}: ${local.apps_security_list_id}"
  vcn_cidr              = var.vcn_cidr
  zone_dns              = var.zone_dns
  rendezvous_ip         = var.rendezvous_ip
  control_plane_count   = var.control_plane_count
  compute_count         = var.compute_count
  public_ssh_key        = var.public_ssh_key
  cluster_name          = var.cluster_name
  webserver_private_ip  = var.webserver_private_ip

  // Dependency on ocir
  use_oracle_cloud_agent = var.use_oracle_cloud_agent
  oca_image_pull_link    = module.ocir.image_pull_command
}

module "resource_attribution_tags" {
  source = "./shared_modules/resource_attribution_tags/find_resource_tags"

  providers = {
    oci = oci.home
  }
  tag_namespace_compartment_ocid_resource_tagging = var.tag_namespace_compartment_ocid_resource_tagging
}
