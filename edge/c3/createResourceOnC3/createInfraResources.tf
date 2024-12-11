terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.38.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.1"
    }
  }
}

variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment where you wish to create the OpenShift cluster."
}

variable "cluster_name" {
  type        = string
  description = "The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible. The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
}

# C3 Region
variable "c3_region" {
  type        = string
  description = "The C3 region name."
}

variable "c3_region_profile_name" {
  type        = string
  description = "The C3 region profile name configured in the ~/.oci/config"
}

provider "oci" {
  region              = var.c3_region
  config_file_profile = var.c3_region_profile_name
}

variable "zone_dns" {
  type        = string
  description = "The name of cluster's DNS zone. This name must be the same as what was specified during OpenShift ISO creation. The zone_dns value must be a valid hostname."
}

variable "image_id_manually_created_on_C3" {
  description = "Manually created on C3 with .oci file with UEFI_64 firmware and launch option 'PARAVIRTUALIZED'"
  type        = string
}

variable "create_openshift_instance_pools" {
  type        = bool
  description = "If the switch is true, the script will create openshift instance pools. Otherwise, it will skip the creation via tf and needs manually creation on C3. Default value is true. Flip on demand, e.g. in agent-based installations."
}

variable "enable_private_dns" {
  type        = bool
  description = "If the switch is enabled, a private DNS zone will be created, and users should edit the /etc/hosts file for resolution. Otherwise, a public DNS zone will be created based on the given domain."
  default     = false
}

data "oci_identity_availability_domain" "availability_domain" {
  compartment_id = var.compartment_ocid
  ad_number      = "1"
}

locals {
  all_protocols                   = "all"
  anywhere                        = "0.0.0.0/0"
  create_openshift_instance_pools = var.create_openshift_instance_pools
  pool_formatter_id               = join("", ["$", "{launchCount}"])
}

##Define network
variable "vcn_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "The IPv4 CIDR blocks for the VCN of your OpenShift Cluster. The default value is 10.0.0.0/16. "
}
variable "vcn_dns_label" {
  default     = "openshiftvcn"
  type        = string
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet (for example, bminstance1.subnet123.vcn1.oraclevcn.com). Must be an alphanumeric string that begins with a letter"
  validation {
    condition     = can(regex("^([a-z0-9]{1,15})$", var.vcn_dns_label))
    error_message = "The vcn_dns_label value must be 1-15 characters. It can use lowercase alphanumeric characters, but must start with a lowercase letter."
  }
}
variable "private_cidr" {
  default     = "10.0.16.0/20"
  type        = string
  description = "The IPv4 CIDR blocks for the private subnet of your OpenShift Cluster. The default value is 10.0.16.0/20. "
}
variable "public_cidr" {
  default     = "10.0.0.0/20"
  type        = string
  description = "The IPv4 CIDR blocks for the public subnet of your OpenShift Cluster. The default value is 10.0.0.0/20. "
}

resource "oci_core_vcn" "openshift_vcn" {
  cidr_blocks = [
    var.vcn_cidr,
  ]
  compartment_id = var.compartment_ocid
  display_name   = var.cluster_name
  dns_label      = var.vcn_dns_label
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "InternetGateway"
  vcn_id         = oci_core_vcn.openshift_vcn.id
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "NatGateway"
}

resource "oci_core_route_table" "public_routes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "public"

  route_rules {
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_route_table" "private_routes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "private"

  route_rules {
    destination       = local.anywhere
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  display_name   = "private"
  vcn_id         = oci_core_vcn.openshift_vcn.id

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = local.all_protocols
  }
  egress_security_rules {
    destination = local.anywhere
    protocol    = local.all_protocols
  }
}

resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  display_name   = "public"
  vcn_id         = oci_core_vcn.openshift_vcn.id

  ingress_security_rules {
    source   = var.vcn_cidr
    protocol = local.all_protocols
  }
  ingress_security_rules {
    source   = local.anywhere
    protocol = "6"
    tcp_options {
      min = 22
      max = 22
    }
  }
  egress_security_rules {
    destination = local.anywhere
    protocol    = local.all_protocols
  }
}

resource "oci_core_subnet" "private" {
  cidr_block     = var.private_cidr
  display_name   = "private"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id

  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "public" {
  cidr_block     = var.public_cidr
  display_name   = "public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.public_routes.id

  security_list_ids = [
    oci_core_security_list.public.id,
  ]

  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
}


# Security group and rules
resource "oci_core_network_security_group" "cluster_lb_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "cluster-lb-nsg"
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_1" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_2" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_3" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_4" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = local.anywhere
  source_type               = "CIDR_BLOCK"
  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_5" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  protocol                  = local.all_protocols
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
}

resource "oci_core_network_security_group" "cluster_controlplane_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "cluster-controlplane-nsg"
}


resource "oci_core_network_security_group_security_rule" "cluster_controlplane_nsg_rule_1" {
  network_security_group_id = oci_core_network_security_group.cluster_controlplane_nsg.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_controlplane_nsg_2" {
  network_security_group_id = oci_core_network_security_group.cluster_controlplane_nsg.id
  protocol                  = local.all_protocols
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
}


resource "oci_core_network_security_group" "cluster_compute_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "cluster-compute-nsg"
}


resource "oci_core_network_security_group_security_rule" "cluster_compute_nsg_rule_1" {
  network_security_group_id = oci_core_network_security_group.cluster_compute_nsg.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_compute_nsg_2" {
  network_security_group_id = oci_core_network_security_group.cluster_compute_nsg.id
  protocol                  = local.all_protocols
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
  source_type               = "CIDR_BLOCK"
}

variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  default     = 500
  type        = number
  description = "Bandwidth in Mbps that determines the maximum bandwidth (ingress plus egress) that the load balancer can achieve. The values must be between minimumBandwidthInMbps and 8000"

  validation {
    condition     = var.load_balancer_shape_details_maximum_bandwidth_in_mbps >= 10 && var.load_balancer_shape_details_maximum_bandwidth_in_mbps <= 8000
    error_message = "The load_balancer_shape_details_maximum_bandwidth_in_mbps value must be between load_balancer_shape_details_minimum_bandwidth_in_mbps and 8000."
  }
}

variable "load_balancer_shape_details_minimum_bandwidth_in_mbps" {
  default     = 10
  type        = number
  description = " Bandwidth in Mbps that determines the total pre-provisioned bandwidth (ingress plus egress). The values must be between 10 and the maximumBandwidthInMbps"

  validation {
    condition     = var.load_balancer_shape_details_minimum_bandwidth_in_mbps >= 10 && var.load_balancer_shape_details_minimum_bandwidth_in_mbps <= 8000
    error_message = "The load_balancer_shape_details_maximum_bandwidth_in_mbps value must be between 10 and load_balancer_shape_details_maximum_bandwidth_in_mbps."
  }
}

resource "oci_load_balancer_load_balancer" "openshift_api_int_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_api_int_lb"
  shape                      = "flexible"
  subnet_ids                 = [oci_core_subnet.private.id]
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.cluster_lb_nsg.id]

  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
}

resource "oci_load_balancer_load_balancer" "openshift_api_apps_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_api_apps_lb"
  shape                      = "flexible"
  subnet_ids                 = var.enable_private_dns ? [oci_core_subnet.private.id] : [oci_core_subnet.public.id]
  is_private                 = var.enable_private_dns ? true : false
  network_security_group_ids = [oci_core_network_security_group.cluster_lb_nsg.id]

  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
}

resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_external" {
  health_checker {
    protocol          = "HTTP"
    port              = 6080
    return_code       = 200
    url_path          = "/readyz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_api_backend"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_external" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_external.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_http_backend" {
  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_ingress_http"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_http" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend.name
  name                     = "openshift_cluster_ingress_http"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_https_backend" {
  health_checker {
    protocol          = "TCP"
    port              = 443
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_ingress_https"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_https" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend.name
  name                     = "openshift_cluster_ingress_https"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_internal" {
  health_checker {
    protocol          = "HTTP"
    port              = 6080
    return_code       = 200
    url_path          = "/readyz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_api_backend"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_internal" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_internal.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend" {
  health_checker {
    protocol          = "HTTP"
    port              = 22624
    return_code       = 200
    url_path          = "/healthz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_infra-mcs"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend.name
  name                     = "openshift_cluster_infra-mcs"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22623
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_2" {
  health_checker {
    protocol          = "HTTP"
    port              = 22624
    return_code       = 200
    url_path          = "/healthz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_infra-mcs_2"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs_2" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2.name
  name                     = "openshift_cluster_infra-mcs_2"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22624
  protocol                 = "TCP"
}

resource "oci_dns_zone" "openshift" {
  compartment_id = var.compartment_ocid
  name           = var.zone_dns
  scope          = var.enable_private_dns ? "PRIVATE" : null
  view_id        = null
  zone_type      = "PRIMARY"
  depends_on     = [oci_core_subnet.private]
}

resource "oci_dns_rrset" "openshift_api" {
  domain = "api.${var.cluster_name}.${var.zone_dns}"
  items {
    domain = "api.${var.cluster_name}.${var.zone_dns}"
    rdata  = oci_load_balancer_load_balancer.openshift_api_apps_lb.ip_address_details[0].ip_address
    rtype  = "A"
    ttl    = "3600"
  }
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift.id
}

resource "oci_dns_rrset" "openshift_apps" {
  domain = "*.apps.${var.cluster_name}.${var.zone_dns}"
  items {
    domain = "*.apps.${var.cluster_name}.${var.zone_dns}"
    rdata  = oci_load_balancer_load_balancer.openshift_api_apps_lb.ip_address_details[0].ip_address
    rtype  = "A"
    ttl    = "3600"
  }
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift.id
}

resource "oci_dns_rrset" "openshift_api_int" {
  domain = "api-int.${var.cluster_name}.${var.zone_dns}"
  items {
    domain = "api-int.${var.cluster_name}.${var.zone_dns}"
    rdata  = oci_load_balancer_load_balancer.openshift_api_int_lb.ip_address_details[0].ip_address
    rtype  = "A"
    ttl    = "3600"
  }
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift.id
}

variable "control_plane_shape" {
  default     = "VM.PCAStandard.E5.Flex" # C3 only support ONE shape
  type        = string
  description = "Compute shape of the control_plane nodes. The default shape is VM.Standard.E4.Flex. For more detail regarding compute shapes, please visit https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm ."
}

variable "compute_shape" {
  default     = "VM.PCAStandard.E5.Flex" # C3 only support ONE shape
  type        = string
  description = "Compute shape of the compute nodes. The default shape is VM.Standard.E4.Flex. For more detail regarding compute shapes, please visit https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm "
}

resource "oci_core_shape_management" "imaging_control_plane_shape" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.image_id_manually_created_on_C3
  shape_name     = var.control_plane_shape
}

resource "oci_core_shape_management" "imaging_compute_shape" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.image_id_manually_created_on_C3
  shape_name     = var.compute_shape
}

# instance
variable "control_plane_count" {
  default     = 3
  type        = number
  description = "The number of control_plane nodes in the cluster. The default value is 3. "
}
variable "control_plane_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs available for the shape of each control_plane node. The default value is 4. "

  validation {
    condition     = var.control_plane_ocpu >= 1 && var.control_plane_ocpu <= 114
    error_message = "The control_plane_ocpu value must be between 1 and 114."
  }
}
variable "control_plane_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each control_plane node, in gigabytes. The default value is 16. "

  validation {
    condition     = var.control_plane_memory >= 1 && var.control_plane_memory <= 1760
    error_message = "The control_plane_memory value must be between the value of control_plane_ocpu and 1760."
  }
}
variable "control_plane_boot_size" {
  default     = 1024
  type        = number
  description = "The size of the boot volume of each control_plane node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 1024 GB. "

  validation {
    condition     = var.control_plane_boot_size >= 50 && var.control_plane_boot_size <= 32768
    error_message = "The control_plane_boot_size value must be between 50 and 32768."
  }
}

variable "compute_count" {
  default     = 3
  type        = number
  description = "The number of compute nodes in the cluster. The default value is 3. "
}
variable "compute_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs available for the shape of each compute node. The default value is 4. "

  validation {
    condition     = var.compute_ocpu >= 1 && var.compute_ocpu <= 114
    error_message = "The compute_ocpu value must be between 1 and 114."
  }
}
variable "compute_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each compute node, in gigabytes. The default value is 16."

  validation {
    condition     = var.compute_memory >= 1 && var.compute_memory <= 1760
    error_message = "The compute_memory value must be between the value of compute_ocpu and 1760."
  }
}
variable "compute_boot_size" {
  default     = 100
  type        = number
  description = "The size of the boot volume of each compute node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 100 GB."

  validation {
    condition     = var.compute_boot_size >= 50 && var.compute_boot_size <= 32768
    error_message = "The compute_boot_size value must be between 50 and 32768."
  }
}

resource "oci_core_instance_configuration" "control_plane_node_config" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-control_plane"
  instance_details {
    instance_type = "compute"
    launch_details {
      availability_domain = data.oci_identity_availability_domain.availability_domain.name
      compartment_id      = var.compartment_ocid
      create_vnic_details {
        assign_private_dns_record = "true"
        assign_public_ip          = "false"
        nsg_ids = [
          oci_core_network_security_group.cluster_controlplane_nsg.id,
        ]
        subnet_id = oci_core_subnet.private.id
      }
      defined_tags = {
        "openshift-${var.cluster_name}.instance-role" = "control_plane"
      }
      shape = var.control_plane_shape
      shape_config {
        memory_in_gbs = var.control_plane_memory
        ocpus         = var.control_plane_ocpu
      }
      source_details {
        boot_volume_size_in_gbs = var.control_plane_boot_size
        image_id                = var.image_id_manually_created_on_C3
        source_type             = "image"
      }
    }
  }
}

resource "oci_core_instance_pool" "control_plane_nodes" {
  count                           = local.create_openshift_instance_pools ? 1 : 0
  compartment_id                  = var.compartment_ocid
  display_name                    = "${var.cluster_name}-control-plane"
  instance_configuration_id       = oci_core_instance_configuration.control_plane_node_config[0].id
  instance_display_name_formatter = "${var.cluster_name}-control-plane-${local.pool_formatter_id}"
  instance_hostname_formatter     = "${var.cluster_name}-control-plane-${local.pool_formatter_id}"

  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_external.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
    port             = "6443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_internal.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
    port             = "6443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
    port             = "22623"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
    port             = "22624"
    vnic_selection   = "PrimaryVnic"
  }
  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.availability_domain.name
    primary_subnet_id   = oci_core_subnet.private.id
  }
  size = var.control_plane_count
}


resource "oci_core_instance_configuration" "compute_node_config" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-compute"
  instance_details {
    instance_type = "compute"
    launch_details {
      availability_domain = data.oci_identity_availability_domain.availability_domain.name
      compartment_id      = var.compartment_ocid
      create_vnic_details {
        assign_private_dns_record = "true"
        assign_public_ip          = "false"
        nsg_ids = [
          oci_core_network_security_group.cluster_compute_nsg.id,
        ]
        subnet_id = oci_core_subnet.private.id
      }
      defined_tags = {
        "openshift-${var.cluster_name}.instance-role" = "compute"
      }
      shape = var.compute_shape
      shape_config {
        memory_in_gbs = var.compute_memory
        ocpus         = var.compute_ocpu
      }
      source_details {
        boot_volume_size_in_gbs = var.compute_boot_size
        image_id                = var.image_id_manually_created_on_C3
        source_type             = "image"
      }
    }
  }
}

resource "oci_core_instance_pool" "compute_nodes" {
  count                           = local.create_openshift_instance_pools ? 1 : 0
  compartment_id                  = var.compartment_ocid
  display_name                    = "${var.cluster_name}-compute"
  instance_configuration_id       = oci_core_instance_configuration.compute_node_config[0].id
  instance_display_name_formatter = "${var.cluster_name}-compute-${local.pool_formatter_id}"
  instance_hostname_formatter     = "${var.cluster_name}-compute-${local.pool_formatter_id}"
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
    port             = "443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
    port             = "80"
    vnic_selection   = "PrimaryVnic"
  }
  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.availability_domain.name
    primary_subnet_id   = oci_core_subnet.private.id
  }
  size = var.compute_count
}

output "open_shift_api_int_lb_addr" {
  value = oci_load_balancer_load_balancer.openshift_api_int_lb.ip_address_details[0].ip_address
}

output "open_shift_api_apps_lb_addr" {
  value = oci_load_balancer_load_balancer.openshift_api_apps_lb.ip_address_details[0].ip_address
}


output "oci_ccm_config" {
  value = <<OCICCMCONFIG
useInstancePrincipals: true
compartment: ${var.compartment_ocid}
vcn: ${oci_core_vcn.openshift_vcn.id}
loadBalancer:
  subnet1: ${var.enable_private_dns ? oci_core_subnet.private.id : oci_core_subnet.public.id}
  securityListManagementMode: Frontend
  securityLists:
    ${var.enable_private_dns ? oci_core_subnet.private.id : oci_core_subnet.public.id}: ${var.enable_private_dns ? oci_core_security_list.private.id : oci_core_security_list.public.id}
rateLimiter:
  rateLimitQPSRead: 20.0
  rateLimitBucketRead: 5
  rateLimitQPSWrite: 20.0
  rateLimitBucketWrite: 5
  OCICCMCONFIG
}