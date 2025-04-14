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

module "resource_attribution_tags" {
  source = "./shared_modules/resource_attribution_tags/create_resource_tags"

  providers = {
    oci = oci.home
  }
  tag_namespace_compartment_ocid_resource_tagging = var.tag_namespace_compartment_ocid_resource_tagging
}
