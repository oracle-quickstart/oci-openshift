terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

# Read existing core networking components by ID
data "oci_core_vcn" "existing_vcn" {
  vcn_id = var.existing_vcn_id
}

data "oci_core_subnet" "existing_private_ocp" {
  subnet_id = var.existing_private_ocp_subnet_id
}

# Network Security Groups discovery by naming convention
locals {
  net_compartment = coalesce(var.networking_compartment_ocid != "" ? var.networking_compartment_ocid : null, var.compartment_ocid)
}

data "oci_core_network_security_groups" "existing_lb_nsgs" {
  compartment_id = local.net_compartment
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*lb.*"]
    regex  = true
  }
}

# Load balancer for the API, discovered by cluster naming convention
data "oci_load_balancer_load_balancers" "openshift_api_lb" {
  compartment_id = local.net_compartment
  display_name   = "${var.cluster_name}-openshift_api_lb"
}
