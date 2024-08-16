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

# Home Region Terraform Provider
provider "oci" {
  alias  = "home"
  region = local.home_region
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
      "control_plane",
      "compute",
    ]
  }
  provider   = oci.home
  depends_on = [oci_identity_tag_namespace.openshift_tags]
}

resource "oci_identity_tag" "openshift_boot_volume_type" {
  description      = "Describe the boot volume type of an OpenShift cluster"
  is_cost_tracking = "false"
  is_retired       = "false"
  name             = "boot-volume-type"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tags.id
  validator {
    validator_type = "ENUM"
    values = [
      "PARAVIRTUALIZED",
      "ISCSI",
    ]
  }
  provider   = oci.home
  depends_on = [oci_identity_tag_namespace.openshift_tags]
}

resource "oci_identity_tag" "openshift_resource" {
  description      = "Openshift Resource"
  is_cost_tracking = "true"
  is_retired       = "false"
  name             = "openshift-resource"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tags.id
  provider         = oci.home
}

resource "oci_identity_dynamic_group" "openshift_control_plane_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift control_plane nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='control_plane'}"
  name           = "${var.cluster_name}_control_plane_nodes"
  provider       = oci.home
  defined_tags   = local.common_defined_tags
  depends_on     = [oci_identity_tag.openshift_instance_role]
}

resource "oci_identity_dynamic_group" "openshift_compute_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift compute nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='compute'}"
  name           = "${var.cluster_name}_compute_nodes"
  provider       = oci.home
  defined_tags   = local.common_defined_tags
  depends_on     = [oci_identity_tag.openshift_instance_role]
}

resource "oci_identity_policy" "openshift_control_plane_nodes" {
  compartment_id = var.compartment_ocid
  description    = "OpenShift control_plane nodes instance principal"
  name           = "${var.cluster_name}_control_plane_nodes"
  defined_tags   = local.common_defined_tags
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage load-balancers in compartment id ${var.compartment_ocid}",
  ]
  provider = oci.home
}

# Wait for tag namespace validation complete before image creation
resource "time_sleep" "wait_60_seconds" {
  depends_on      = [oci_identity_tag_namespace.openshift_tags]
  create_duration = "60s"
}


resource "oci_core_image" "openshift_image" {
  count          = var.create_openshift_instances ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = var.cluster_name
  launch_mode    = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "NATIVE"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
  defined_tags = local.common_defined_tags
  depends_on   = [time_sleep.wait_60_seconds]
}

resource "oci_core_shape_management" "imaging_control_plane_shape" {
  count          = var.create_openshift_instances ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.openshift_image[0].id
  shape_name     = var.control_plane_shape
}

resource "oci_core_shape_management" "imaging_compute_shape" {
  count          = var.create_openshift_instances ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.openshift_image[0].id
  shape_name     = var.compute_shape
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema" {
  count                                               = var.create_openshift_instances ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image[0].id
  schema_data                                         = merge(local.schema_firmware, local.schema_boot_volume_type, local.schema_launch_mode, local.schema_local_volume_data_type, local.schema_remote_volume_data_type, local.schema_storage_iscsi_multipath_device_supported)
  defined_tags                                        = local.common_defined_tags
}

# Wait for tag namespace validation complete before image creation
resource "time_sleep" "wait_180_seconds_vcn" {
  depends_on      = [oci_core_image.openshift_image]
  create_duration = "180s"
}

##Define network
resource "oci_core_vcn" "openshift_vcn" {
  cidr_blocks = [
    var.vcn_cidr,
  ]
  compartment_id = var.compartment_ocid
  display_name   = var.cluster_name
  dns_label      = var.vcn_dns_label
  depends_on     = [time_sleep.wait_180_seconds_vcn]
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "InternetGateway"
  vcn_id         = oci_core_vcn.openshift_vcn.id
  defined_tags   = local.common_defined_tags
}

resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "NatGateway"
  defined_tags   = local.common_defined_tags
}

resource "oci_core_service_gateway" "service_gateway" {
  #Required
  compartment_id = var.compartment_ocid
  services {
    service_id = data.oci_core_services.oci_services.services[0]["id"]
  }
  vcn_id       = oci_core_vcn.openshift_vcn.id
  display_name = "ServiceGateway"
  defined_tags = local.common_defined_tags
}

resource "oci_core_route_table" "public_routes" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  display_name   = "public"
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "private2" {
  count          = local.is_control_plane_iscsi_type || local.is_compute_iscsi_type ? 1 : 0
  cidr_block     = var.private_cidr_2
  display_name   = "private_two"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id
  defined_tags   = local.common_defined_tags
  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "private2"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "public" {
  cidr_block     = var.public_cidr
  display_name   = "public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.public_routes.id
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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
  defined_tags   = local.common_defined_tags
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

resource "oci_load_balancer_load_balancer" "openshift_api_int_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_api_int_lb"
  shape                      = "flexible"
  subnet_ids                 = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? [oci_core_subnet.private.id] : [oci_core_subnet.private2[0].id]
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.cluster_lb_nsg.id]
  defined_tags               = local.common_defined_tags

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
  defined_tags               = local.common_defined_tags

  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
}

resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_set_external" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_external.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_http_backend_set" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend_set.name
  name                     = "openshift_cluster_ingress_http"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_https_backend_set" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend_set.name
  name                     = "openshift_cluster_ingress_https"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_set_internal" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_internal.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_set" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set.name
  name                     = "openshift_cluster_infra-mcs"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22623
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_set_2" {
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
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_2.name
  name                     = "openshift_cluster_infra-mcs_2"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22624
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend" "openshift_cluster_api_backend_set_external_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_external.name
  port             = 6443
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cp_cluster_ingress_https_backend_set_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend_set.name
  port             = 443
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cp_cluster_ingress_http_backend_set_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend_set.name
  port             = 80
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_api_backend_set_internal_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_internal.name
  port             = 6443
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_infra-mcs_backend_set_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set.name
  port             = 22623
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_infra-mcs_backend_set_2_backends" {
  for_each         = var.create_openshift_instances ? local.cp_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_2.name
  port             = 22624
  ip_address       = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? data.oci_core_vnic.control_plane_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.control_plane_secondary_vnic[each.key].private_ip_address
}


resource "oci_load_balancer_backend" "openshift_cluster_ingress_https_backend_set_backends" {
  for_each         = var.create_openshift_instances ? local.compute_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend_set.name
  port             = 443
  ip_address       = !local.is_compute_iscsi_type ? data.oci_core_vnic.compute_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.compute_secondary_vnic[each.key].private_ip_address
}

resource "oci_load_balancer_backend" "openshift_cluster_ingress_http_backend_set_backends" {
  for_each         = var.create_openshift_instances ? local.compute_node_map : {}
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_apps_lb.id
  backendset_name  = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend_set.name
  port             = 80
  ip_address       = !local.is_compute_iscsi_type ? data.oci_core_vnic.compute_primary_vnic[each.key].private_ip_address : data.oci_core_vnic.compute_secondary_vnic[each.key].private_ip_address
}

resource "oci_dns_zone" "openshift" {
  compartment_id = var.compartment_ocid
  name           = var.zone_dns
  scope          = var.enable_private_dns ? "PRIVATE" : null
  view_id        = var.enable_private_dns ? data.oci_dns_resolver.dns_resolver.default_view_id : null
  zone_type      = "PRIMARY"
  depends_on     = [oci_core_subnet.private]
  defined_tags   = local.common_defined_tags
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

resource "time_sleep" "wait_180_seconds" {
  depends_on      = [oci_core_vcn.openshift_vcn]
  create_duration = "180s"
}

resource "oci_core_vnic_attachment" "control_plane_secondary_vnic_attachment" {
  for_each = var.create_openshift_instances && (local.is_control_plane_iscsi_type || local.is_compute_iscsi_type) ? local.cp_node_map : {}
  #Required
  create_vnic_details {
    #Optional
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    defined_tags = {
      "openshift-${var.cluster_name}.boot-volume-type"   = "ISCSI"
      "openshift-${var.cluster_name}.openshift-resource" = "openshift-resource"
    }
    display_name   = "vnic2"
    hostname_label = oci_core_instance.control_plane_node[each.key].display_name
    nsg_ids        = [oci_core_network_security_group.cluster_controlplane_nsg.id, ]
    subnet_id      = oci_core_subnet.private2[0].id
  }
  instance_id = oci_core_instance.control_plane_node[each.key].id

  #Optional
  display_name = "vnic2"
  nic_index    = local.is_control_plane_iscsi_type ? 1 : 0
}

resource "oci_core_vnic_attachment" "compute_secondary_vnic_attachment" {
  for_each = var.create_openshift_instances && local.is_compute_iscsi_type ? local.compute_node_map : {}
  #Required
  create_vnic_details {

    #Optional
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    defined_tags = {
      "openshift-${var.cluster_name}.boot-volume-type"   = "ISCSI"
      "openshift-${var.cluster_name}.openshift-resource" = "openshift-resource"
    }
    display_name   = "vnic2"
    hostname_label = oci_core_instance.compute_node[each.key].display_name
    nsg_ids        = [oci_core_network_security_group.cluster_compute_nsg.id, ]
    subnet_id      = oci_core_subnet.private2[0].id
  }
  instance_id = oci_core_instance.compute_node[each.key].id

  #Optional
  display_name = "vnic2"
  nic_index    = 1
}

resource "oci_core_instance" "control_plane_node" {
  for_each            = var.create_openshift_instances ? local.cp_node_map  : {}
  compartment_id      = var.compartment_ocid
  availability_domain = each.value.ad_name
  display_name        = "${var.cluster_name}-cp-${each.value.index}-ad${regex("\\d+$", each.value.ad_name)}"
  shape               = var.control_plane_shape
  defined_tags = {
    "openshift-${var.cluster_name}.instance-role"      = "control_plane"
    "openshift-${var.cluster_name}.openshift-resource" = "openshift-resource"
  }
  depends_on = [oci_identity_tag_namespace.openshift_tags]

  create_vnic_details {
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    nsg_ids = [
      oci_core_network_security_group.cluster_controlplane_nsg.id,
    ]
    subnet_id = oci_core_subnet.private.id
  }

  source_details {
    source_type             = "image"
    boot_volume_size_in_gbs = var.control_plane_boot_size
    boot_volume_vpus_per_gb = var.control_plane_boot_volume_vpus_per_gb
    source_id               = oci_core_image.openshift_image[0].id
  }

  dynamic "shape_config" {
    for_each = local.is_control_plane_iscsi_type ? [] : [1]
    content {
      memory_in_gbs = var.control_plane_memory
      ocpus         = var.control_plane_ocpu
    }
  }
}

resource "oci_core_instance" "compute_node" {
  for_each            = var.create_openshift_instances ? local.compute_node_map : {}
  compartment_id      = var.compartment_ocid
  availability_domain = each.value.ad_name
  display_name        = "${var.cluster_name}-compute-${each.value.index}-ad${regex("\\d+$", each.value.ad_name)}"
  shape               = var.compute_shape
  defined_tags = {
    "openshift-${var.cluster_name}.instance-role"      = "compute"
    "openshift-${var.cluster_name}.openshift-resource" = "openshift-resource"
  }
  depends_on = [oci_identity_tag_namespace.openshift_tags]

  create_vnic_details {
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    subnet_id                 = oci_core_subnet.private.id
    nsg_ids = [
      oci_core_network_security_group.cluster_compute_nsg.id,
    ]
  }

  source_details {
    source_type             = "image"
    boot_volume_size_in_gbs = var.compute_boot_size
    boot_volume_vpus_per_gb = var.compute_boot_volume_vpus_per_gb
    source_id               = oci_core_image.openshift_image[0].id
  }

  dynamic "shape_config" {
    for_each = local.is_compute_iscsi_type ? [] : [1] # Only include shape_config if apply_vm_shape is true
    content {
      memory_in_gbs = var.compute_memory
      ocpus         = var.compute_ocpu
    }
  }
}