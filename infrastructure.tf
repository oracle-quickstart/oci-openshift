## Infra Region or Default Region of the Current RMS Stack
variable "region" {}

variable "zone_dns" {
  type        = string
  description = "The name of cluster's DNS zone. This name must be the same as what was specified during OpenShift ISO creation."

  validation {
    condition     = can(regex("^((?!-)[A-Za-z0-9-]{1, 63}(?<!-)\\.)+[A-Za-z]{2, 6}$", var.zone_dns))
    error_message = "The zone_dns value must be a valid hostname."
  }
}
variable "master_count" {
  default     = 3
  type        = number
  description = "The number of master nodes in the cluster. The default value is 3. "
}
variable "master_shape" {
  default     = "VM.Standard.E4.Flex"
  description = "Compute shape of the master nodes. The default shape is VM.Standard.E4.Flex. For more detail regarding compute shapes, please visit https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm ."
}
variable "master_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs available for the shape of each master node. The default value is 4. "

  validation {
    condition     = var.master_ocpu >= 1 && var.master_ocpu <= 114
    error_message = "The master_ocpu value must be between 1 and 114."
  }
}
variable "master_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each master node, in gigabytes. The default value is 16. "

  validation {
    condition     = var.master_memory >= 1 && var.master_memory <= 1760
    error_message = "The master_memory value must be between the value of master_ocpu and 1760."
  }
}
variable "master_boot_size" {
  default     = 1024
  type        = number
  description = "The size of the boot volume of each master node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 1024 GB. "

  validation {
    condition     = var.master_boot_size >= 50 && var.master_boot_size <= 32768
    error_message = "The master_boot_size value must be between 50 and 32768."
  }
}
variable "master_boot_volume_vpus_per_gb" {
  default     = 90
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each master node. The default value is 90. "

  validation {
    condition     = var.master_boot_volume_vpus_per_gb >= 10 && var.master_boot_volume_vpus_per_gb <= 120 && var.master_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The master_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}
variable "worker_count" {
  default     = 3
  type        = number
  description = "The number of worker nodes in the cluster. The default value is 3. "
}
variable "worker_shape" {
  default     = "VM.Standard.E4.Flex"
  description = "Compute shape of the worker nodes. The default shape is VM.Standard.E4.Flex. For more detail regarding compute shapes, please visit https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm "
}
variable "worker_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs available for the shape of each worker node. The default value is 4. "

  validation {
    condition     = var.worker_ocpu >= 1 && var.worker_ocpu <= 114
    error_message = "The worker_ocpu value must be between 1 and 114."
  }
}
variable "worker_boot_volume_vpus_per_gb" {
  default     = 30
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each worker node. The default value is 30. "

  validation {
    condition     = var.worker_boot_volume_vpus_per_gb >= 10 && var.worker_boot_volume_vpus_per_gb <= 120 && var.worker_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The worker_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}
variable "worker_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each worker node, in gigabytes. The default value is 16."

  validation {
    condition     = var.worker_memory >= 1 && var.worker_memory <= 1760
    error_message = "The worker_memory value must be between the value of worker_ocpu and 1760."
  }
}
variable "worker_boot_size" {
  default     = 100
  type        = number
  description = "The size of the boot volume of each worker node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 100 GB."

  validation {
    condition     = var.worker_boot_size >= 50 && var.worker_boot_size <= 32768
    error_message = "The worker_boot_size value must be between 50 and 32768."
  }
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
variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}

## Openshift infrastructure compartment
variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment where you wish to create the OpenShift cluster."
}

## Openshift cluster name
variable "cluster_name" {
  type        = string
  description = "The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible."

  validation {
    condition     = can(regex("^((?!-)[a-z0-9-]{1, 54}(?<!-))$", var.cluster_name))
    error_message = "The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
  }
}

variable "vcn_cidr" {
  default     = "10.0.0.0/16"
  description = "The IPv4 CIDR blocks for the VCN of your OpenShift Cluster. The default value is 10.0.0.0/16. "
}
variable "vcn_dns_label" {
  default     = "openshiftvcn"
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet (for example, bminstance1.subnet123.vcn1.oraclevcn.com). Must be an alphanumeric string that begins with a letter"
  validation {
    condition     = can(regex("^([a-z0-9]{1, 15})$", var.vcn_dns_label))
    error_message = "The vcn_dns_label value must be 1-15 characters. It can use lowercase alphanumeric characters, but must start with a lowercase letter."
  }
}
variable "private_cidr" {
  default     = "10.0.16.0/20"
  description = "The IPv4 CIDR blocks for the private subnet of your OpenShift Cluster. The default value is 10.0.16.0/20. "
}
variable "public_cidr" {
  default     = "10.0.0.0/20"
  description = "The IPv4 CIDR blocks for the public subnet of your OpenShift Cluster. The default value is 10.0.0.0/20. "
}

variable "openshift_image_source_uri" {
  type        = string
  description = "The OCI Object Storage URL for the OpenShift image. Before provisioning resources through this Resource Manager stack, users should upload the OpenShift image to OCI Object Storage, create a pre-authenticated requests (PAR) uri, and paste the uri to this block. For more detail regarding Object storage and PAR, please visit https://docs.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm and https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingpreauthenticatedrequests.htm ."
}

variable "enable_private_dns" {
  type        = bool
  description = "If the switch is enabled, a private DNS zone will be created, and users should edit the /etc/hosts file for resolution. Otherwise, a public DNS zone will be created based on the given domain."
  default     = false
}

# Reginal Infrastructure Terraform Provider
provider "oci" {
  region = var.region
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_region_subscriptions" "region_subscriptions" {
  tenancy_id = var.tenancy_ocid
  filter {
    name   = "region_name"
    values = [var.region]
  }
}

data "oci_identity_regions" "regions" {}

locals {
  region_map = {
    for r in data.oci_identity_regions.regions.regions :
    r.key => r.name
  }

  home_region = lookup(local.region_map, data.oci_identity_tenancy.tenancy.home_region_key)
}

# Home Region Terraform Provider
provider "oci" {
  alias  = "home"
  region = local.home_region
}

locals {
  all_protocols                   = "all"
  anywhere                        = "0.0.0.0/0"
  create_openshift_instance_pools = true
  pool_formatter_id               = join("", ["$", "{launchCount}"])
}

data "oci_identity_availability_domain" "availability_domain" {
  compartment_id = var.compartment_ocid
  ad_number      = "1"
}

##Defined tag namespace. Use to mark instance roles and configure instance policy
resource "oci_identity_tag_namespace" "openshift_tags" {
  compartment_id = var.compartment_ocid
  description    = "Used for track openshift related resources and policies"
  is_retired     = "false"
  name           = "openshift-${var.cluster_name}"
  provider       = oci.home
}

resource "oci_identity_tag" "openshift_instance_role" {
  description      = "Describe instance role inside OpenShift cluster"
  is_cost_tracking = "false"
  is_retired       = "false"
  name             = "instance-role"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tags.id
  validator {
    validator_type = "ENUM"
    values = [
      "master",
      "worker",
    ]
  }
  provider = oci.home
}

data "oci_core_compute_global_image_capability_schemas" "image_capability_schemas" {
}

locals {
  global_image_capability_schemas = data.oci_core_compute_global_image_capability_schemas.image_capability_schemas.compute_global_image_capability_schemas
  image_schema_data = {
    "Compute.Firmware" = "{\"values\": [\"UEFI_64\"],\"defaultValue\": \"UEFI_64\",\"descriptorType\": \"enumstring\",\"source\": \"IMAGE\"}"
  }
}

resource "oci_core_image" "openshift_image" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = var.cluster_name
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
}

resource "oci_core_shape_management" "imaging_master_shape" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.openshift_image[0].id
  shape_name     = var.master_shape
}

resource "oci_core_shape_management" "imaging_worker_shape" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.openshift_image[0].id
  shape_name     = var.worker_shape
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema" {
  count                                               = local.create_openshift_instance_pools ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image[0].id
  schema_data                                         = local.image_schema_data
}

##Define network
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

data "oci_core_services" "oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "service_gateway" {
  #Required
  compartment_id = var.compartment_ocid

  services {
    service_id = data.oci_core_services.oci_services.services[0]["id"]
  }

  vcn_id = oci_core_vcn.openshift_vcn.id

  display_name = "ServiceGateway"
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
  route_rules {
    destination       = data.oci_core_services.oci_services.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gateway.id
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

resource "oci_core_network_security_group" "cluster_lb_nsg" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "cluster-lb-nsg"
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_1" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  direction                 = "EGRESS"
  destination               = local.anywhere
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_lb_nsg_rule_2" {
  network_security_group_id = oci_core_network_security_group.cluster_lb_nsg.id
  protocol                  = "6"
  direction                 = "INGRESS"
  source                    = local.anywhere
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
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_controlplane_nsg_2" {
  network_security_group_id = oci_core_network_security_group.cluster_controlplane_nsg.id
  protocol                  = local.all_protocols
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
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
  protocol                  = local.all_protocols
}

resource "oci_core_network_security_group_security_rule" "cluster_compute_nsg_2" {
  network_security_group_id = oci_core_network_security_group.cluster_compute_nsg.id
  protocol                  = local.all_protocols
  direction                 = "INGRESS"
  source                    = var.vcn_cidr
}

resource "oci_load_balancer_load_balancer" "openshift_internal_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_internal_lb"
  shape                      = "flexible"
  subnet_ids                 = [oci_core_subnet.private.id]
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.cluster_lb_nsg.id]

  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
}

resource "oci_load_balancer_load_balancer" "openshift_external_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_external_lb"
  shape                      = "flexible"
  subnet_ids                 = [oci_core_subnet.public.id]
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.cluster_lb_nsg.id]

  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
}

locals {
  lb_private_addr = element([
    for address in oci_load_balancer_load_balancer.openshift_internal_lb.ip_address_details : address
    if address.is_public == false
  ], 0).ip_address
  lb_public_addr = element([
    for address in oci_load_balancer_load_balancer.openshift_external_lb.ip_address_details : address
    if address.is_public == true
  ], 0).ip_address
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_external_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_external" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_external.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_external_lb.id
  port                     = 6443
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_api_backend_external]
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_external_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_http" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend.name
  name                     = "openshift_cluster_ingress_http"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_external_lb.id
  port                     = 80
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend]
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_external_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_https" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend.name
  name                     = "openshift_cluster_ingress_https"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_external_lb.id
  port                     = 443
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend]
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_internal_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_internal" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_internal.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_internal_lb.id
  port                     = 6443
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_api_backend_internal]
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_internal_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend.name
  name                     = "openshift_cluster_infra-mcs"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_internal_lb.id
  port                     = 22623
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend]
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
  load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
  policy           = "LEAST_CONNECTIONS"
  depends_on       = [oci_load_balancer_load_balancer.openshift_internal_lb]
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs_2" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2.name
  name                     = "openshift_cluster_infra-mcs_2"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_internal_lb.id
  port                     = 22624
  protocol                 = "TCP"
  depends_on               = [oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2]
}

resource "oci_identity_dynamic_group" "openshift_master_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift master nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='master'}"
  name           = "${var.cluster_name}_master_nodes"
  provider       = oci.home
}

resource "oci_identity_policy" "openshift_master_nodes" {
  compartment_id = var.compartment_ocid
  description    = "OpenShift master nodes instance principal"
  name           = "${var.cluster_name}_master_nodes"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_master_nodes.name} to manage volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_master_nodes.name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_master_nodes.name} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_master_nodes.name} to use virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_master_nodes.name} to manage load-balancers in compartment id ${var.compartment_ocid}",
  ]
  provider = oci.home
}

resource "oci_identity_dynamic_group" "openshift_worker_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift worker nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='worker'}"
  name           = "${var.cluster_name}_worker_nodes"
  provider       = oci.home
}

resource "oci_dns_zone" "openshift" {
  compartment_id = var.compartment_ocid
  name           = var.zone_dns
  scope          = var.enable_private_dns ? "PRIVATE" : null
  view_id        = var.enable_private_dns ? data.oci_dns_resolver.dns_resolver.default_view_id : null
  zone_type      = "PRIMARY"
  depends_on     = [oci_core_subnet.private]
}

resource "oci_dns_rrset" "openshift_api" {
  domain = "api.${var.cluster_name}.${var.zone_dns}"
  items {
    domain = "api.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.enable_private_dns ? local.lb_private_addr : local.lb_public_addr
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
    rdata  = var.enable_private_dns ? local.lb_private_addr : local.lb_public_addr
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
    rdata  = local.lb_private_addr
    rtype  = "A"
    ttl    = "3600"
  }
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift.id
}

resource "time_sleep" "wait_180_seconds" {
  depends_on      = [oci_core_vcn.openshift_vcn]
  create_duration = "180s"
}

data "oci_core_vcn_dns_resolver_association" "dns_resolver_association" {
  vcn_id     = oci_core_vcn.openshift_vcn.id
  depends_on = [time_sleep.wait_180_seconds]
}

data "oci_dns_resolver" "dns_resolver" {
  depends_on = [
    data.oci_core_vcn_dns_resolver_association.dns_resolver_association
  ]
  resolver_id = data.oci_core_vcn_dns_resolver_association.dns_resolver_association.dns_resolver_id
  scope       = "PRIVATE"
}

resource "oci_core_instance_configuration" "master_node_config" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-master"
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
        "openshift-${var.cluster_name}.instance-role" = "master"
      }
      shape = var.master_shape
      shape_config {
        memory_in_gbs = var.master_memory
        ocpus         = var.master_ocpu
      }
      source_details {
        boot_volume_size_in_gbs = var.master_boot_size
        boot_volume_vpus_per_gb = var.master_boot_volume_vpus_per_gb
        image_id                = oci_core_image.openshift_image[0].id
        source_type             = "image"
      }
    }
  }
}

resource "oci_core_instance_pool" "master_nodes" {
  count                           = local.create_openshift_instance_pools ? 1 : 0
  compartment_id                  = var.compartment_ocid
  display_name                    = "${var.cluster_name}-master"
  instance_configuration_id       = oci_core_instance_configuration.master_node_config[0].id
  instance_display_name_formatter = "${var.cluster_name}-master-${local.pool_formatter_id}"
  instance_hostname_formatter     = "${var.cluster_name}-master-${local.pool_formatter_id}"
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_external.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
    port             = "6443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_internal.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
    port             = "6443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
    port             = "22623"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_internal_lb.id
    port             = "22624"
    vnic_selection   = "PrimaryVnic"
  }
  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.availability_domain.name
    primary_subnet_id   = oci_core_subnet.private.id
  }
  size = var.master_count
  depends_on = [
    oci_load_balancer_backend_set.openshift_cluster_api_backend_external,
    oci_load_balancer_backend_set.openshift_cluster_api_backend_internal,
    oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend,
    oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_2,
    oci_core_instance_configuration.master_node_config,
  ]
}

resource "oci_core_instance_configuration" "worker_node_config" {
  count          = local.create_openshift_instance_pools ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-worker"
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
        "openshift-${var.cluster_name}.instance-role" = "worker"
      }
      shape = var.worker_shape
      shape_config {
        memory_in_gbs = var.worker_memory
        ocpus         = var.worker_ocpu
      }
      source_details {
        boot_volume_size_in_gbs = var.worker_boot_size
        boot_volume_vpus_per_gb = var.worker_boot_volume_vpus_per_gb
        image_id                = oci_core_image.openshift_image[0].id
        source_type             = "image"
      }
    }
  }
}

resource "oci_core_instance_pool" "worker_nodes" {
  count                           = local.create_openshift_instance_pools ? 1 : 0
  compartment_id                  = var.compartment_ocid
  display_name                    = "${var.cluster_name}-worker"
  instance_configuration_id       = oci_core_instance_configuration.worker_node_config[0].id
  instance_display_name_formatter = "${var.cluster_name}-worker-${local.pool_formatter_id}"
  instance_hostname_formatter     = "${var.cluster_name}-worker-${local.pool_formatter_id}"
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
    port             = "443"
    vnic_selection   = "PrimaryVnic"
  }
  load_balancers {
    backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend.name
    load_balancer_id = oci_load_balancer_load_balancer.openshift_external_lb.id
    port             = "80"
    vnic_selection   = "PrimaryVnic"
  }
  placement_configurations {
    availability_domain = data.oci_identity_availability_domain.availability_domain.name
    primary_subnet_id   = oci_core_subnet.private.id
  }
  size = var.worker_count
  depends_on = [
    oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend,
    oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend,
    oci_core_instance_configuration.worker_node_config,
  ]
}

output "open_shift_lb_private_addr" {
  value = local.lb_private_addr
}

output "open_shift_lb_public_addr" {
  value = local.lb_public_addr
}

output "oci_ccm_config" {
  value = <<OCICCMCONFIG
useInstancePrincipals: true
compartment: ${var.compartment_ocid}
vcn: ${oci_core_vcn.openshift_vcn.id}
loadBalancer:
  subnet1: ${oci_core_subnet.public.id}
  securityListManagementMode: Frontend
  securityLists:
    ${oci_core_subnet.public.id}: ${oci_core_security_list.public.id}
rateLimiter:
  rateLimitQPSRead: 20.0
  rateLimitBucketRead: 5
  rateLimitQPSWrite: 20.0
  rateLimitBucketWrite: 5
  OCICCMCONFIG
}
