terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

resource "oci_load_balancer_load_balancer" "openshift_api_int_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_api_int_lb"
  shape                      = "flexible"
  subnet_ids                 = [var.op_subnet_private_ocp]
  is_private                 = true
  network_security_group_ids = [var.op_network_security_group_cluster_lb_nsg]
  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
  defined_tags = var.defined_tags
}

resource "oci_load_balancer_load_balancer" "openshift_api_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_api_lb"
  shape                      = "flexible"
  subnet_ids                 = var.enable_public_api_lb ? [var.op_subnet_public] : [var.op_subnet_private_ocp]
  is_private                 = var.enable_public_api_lb ? false : true
  network_security_group_ids = [var.op_network_security_group_cluster_lb_nsg]
  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
  defined_tags = var.defined_tags
}

resource "oci_load_balancer_load_balancer" "openshift_apps_lb" {
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-openshift_apps_lb"
  shape                      = "flexible"
  subnet_ids                 = var.enable_public_apps_lb ? [var.op_subnet_public] : [var.op_subnet_private_ocp]
  is_private                 = var.enable_public_apps_lb ? false : true
  network_security_group_ids = [var.op_network_security_group_cluster_lb_nsg]
  shape_details {
    maximum_bandwidth_in_mbps = var.load_balancer_shape_details_maximum_bandwidth_in_mbps
    minimum_bandwidth_in_mbps = var.load_balancer_shape_details_minimum_bandwidth_in_mbps
  }
  defined_tags = var.defined_tags
}
