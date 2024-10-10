terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.38.0"
    }
  }
}

# Home Region Terraform Provider
provider "oci" {
  alias  = "home"
}

variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment that will contain tagging and OpenShift resources."
}

data "oci_identity_compartment" "compartment" {
  id = var.compartment_ocid
}

# Defined tag namespace (scoped to compartment). Used to mark cluster resources, instance roles, and configure instance policy
resource "oci_identity_tag_namespace" "openshift_tags" {
  compartment_id = var.compartment_ocid
  description    = "Used for track openshift related resources and policies"
  is_retired     = "false"
  name           = "openshift-tags-${data.oci_identity_compartment.compartment.name}"
  provider       = oci.home
  lifecycle {
    prevent_destroy = true
  }
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
  lifecycle {
    prevent_destroy = true
  }
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
  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_identity_tag" "openshift_resource" {
  description      = "Openshift Resource"
  is_cost_tracking = "true"
  is_retired       = "false"
  name             = "openshift-resource"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tags.id
  provider         = oci.home
  lifecycle {
    prevent_destroy = true
  }
}