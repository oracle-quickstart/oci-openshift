terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

# Home Region Terraform Provider
provider "oci" {
  alias = "home"
}

variable "tag_namespace_compartment_ocid" {
  type        = string
  description = "Compartment to create tag namespace in. Defaults to current compartment."
}

variable "tag_namespace_name" {
  type        = string
  description = "Name of tag namespace to create for tagging OpenShift OCI resources. WARNING - Tag namespace name must be unique accross the tenancy."
}

# Defined tag namespace (scoped to compartment). Used to mark cluster resources, instance roles, and configure instance policy
resource "oci_identity_tag_namespace" "openshift_tags" {
  compartment_id = var.tag_namespace_compartment_ocid
  description    = "OpenShift related resources and policies"
  is_retired     = "false"
  name           = var.tag_namespace_name
  provider       = oci.home
}

resource "oci_identity_tag" "openshift_instance_role" {
  description      = "Describe instance role of an instance in an OpenShift cluster"
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
  provider = oci.home
}

resource "oci_identity_tag" "openshift_boot_volume_type" {
  description      = "Describe the boot volume type of an instance in an OpenShift cluster"
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
  depends_on = [oci_identity_tag.openshift_instance_role]
}

resource "oci_identity_tag" "openshift_resource" {
  description      = "OpenShift related resource"
  is_cost_tracking = "true"
  is_retired       = "false"
  name             = "openshift-resource"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tags.id
  provider         = oci.home
  depends_on       = [oci_identity_tag.openshift_boot_volume_type]
}
