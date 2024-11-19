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

module "tags" {
  source = "./shared_modules/tags"

  providers = {
    oci = oci.home
  }

  use_existing_tags                      = false
  compartment_ocid                       = var.tag_namespace_compartment_ocid
  tag_namespace_compartment_ocid         = var.tag_namespace_compartment_ocid
  tag_namespace_name                     = var.tag_namespace_name
  cluster_name                           = ""
  openshift_tag_openshift_resource_value = local.openshift_tag_openshift_resource_value
  wait_for_new_tag_consistency_wait_time = "5s"
}
