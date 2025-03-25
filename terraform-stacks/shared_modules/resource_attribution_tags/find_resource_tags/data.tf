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


data "oci_identity_tag_namespaces" "openshift_tag_namespace_attribution" {
  compartment_id = var.tag_namespace_compartment_ocid_resource_tagging
  state          = "ACTIVE"
  filter {
    name   = "name"
    values = [var.openshift_attribution_tag_namespace]
    regex  = true
  }
}

data "oci_identity_tag" "openshift_tag_openshift_resource" {
  tag_name         = var.openshift_attribution_tag_key
  tag_namespace_id = data.oci_identity_tag_namespaces.openshift_tag_namespace_attribution.tag_namespaces[0].id
}
