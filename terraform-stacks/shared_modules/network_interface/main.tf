terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

module "network" {
  count  = var.use_existing_network ? 0 : 1
  source = "./network"

  compartment_ocid = var.compartment_ocid
  cluster_name     = var.cluster_name

  vcn_cidr                = var.vcn_cidr
  private_cidr_ocp        = var.private_cidr_ocp
  private_cidr_bare_metal = var.private_cidr_bare_metal
  public_cidr             = var.public_cidr
  vcn_dns_label           = var.vcn_dns_label

  // Depedency on tags
  defined_tags = var.defined_tags
}

module "network_validator" {
  count  = var.use_existing_network ? 1 : 0
  source = "./network_validator"

  compartment_ocid = var.networking_compartment_ocid

  existing_vcn_id                       = var.existing_vcn_id
  existing_public_subnet_id             = var.existing_public_subnet_id
  existing_private_bare_metal_subnet_id = var.existing_private_bare_metal_subnet_id
  existing_private_ocp_subnet_id        = var.existing_private_ocp_subnet_id
}
