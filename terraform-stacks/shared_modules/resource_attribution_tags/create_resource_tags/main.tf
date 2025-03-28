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

# Defined tag namespace (scoped to compartment). Used for tracking openshift related resources for attribution and reporting
resource "oci_identity_tag_namespace" "openshift_resource" {
  compartment_id = var.tag_namespace_compartment_ocid_resource_tagging
  description    = "Used for tracking openshift related resources for attribution and reporting"
  is_retired     = "false"
  name           = var.openshift_attribution_tag_namespace
}


resource "oci_identity_tag" "openshift_tag_openshift_resource" {
  description      = "OpenShift Resource Tracking"
  is_cost_tracking = "true"
  is_retired       = "false"
  name             = var.openshift_attribution_tag_key
  tag_namespace_id = oci_identity_tag_namespace.openshift_resource.id
  depends_on       = [oci_identity_tag_namespace.openshift_resource]
}
