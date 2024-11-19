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

# Defined tag namespace (scoped to compartment). Used to mark cluster resources, instance roles, and configure instance policy
resource "oci_identity_tag_namespace" "openshift_tag_namespace" {
  count          = var.use_existing_tags ? 0 : 1
  compartment_id = var.tag_namespace_compartment_ocid != "" ? var.tag_namespace_compartment_ocid : var.compartment_ocid
  description    = "Used for track openshift related resources and policies"
  is_retired     = "false"
  name           = var.tag_namespace_name != "" ? var.tag_namespace_name : "openshift-${var.cluster_name}"
}

resource "oci_identity_tag" "openshift_tag_instance_role" {
  count            = var.use_existing_tags ? 0 : 1
  description      = "Describe instance role inside OpenShift cluster"
  is_cost_tracking = "false"
  is_retired       = "false"
  name             = "instance-role"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tag_namespace[0].id
  validator {
    validator_type = "ENUM"
    values = [
      "control_plane",
      "compute",
    ]
  }
}

resource "oci_identity_tag" "openshift_tag_boot_volume_type" {
  count            = var.use_existing_tags ? 0 : 1
  description      = "Describe the boot volume type of an OpenShift cluster"
  is_cost_tracking = "false"
  is_retired       = "false"
  name             = "boot-volume-type"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tag_namespace[0].id
  validator {
    validator_type = "ENUM"
    values = [
      "PARAVIRTUALIZED",
      "ISCSI",
    ]
  }
  depends_on = [oci_identity_tag.openshift_tag_instance_role]
}

resource "oci_identity_tag" "openshift_tag_openshift_resource" {
  count            = var.use_existing_tags ? 0 : 1
  description      = "OpenShift Resource"
  is_cost_tracking = "true"
  is_retired       = "false"
  name             = "openshift-resource"
  tag_namespace_id = oci_identity_tag_namespace.openshift_tag_namespace[0].id
  depends_on       = [oci_identity_tag.openshift_tag_boot_volume_type]
}

resource "time_sleep" "wait_for_new_tag_consistency" {
  depends_on      = [data.oci_identity_tag.openshift_tag_openshift_resource, oci_identity_tag.openshift_tag_openshift_resource]
  create_duration = var.use_existing_tags ? "5s" : var.wait_for_new_tag_consistency_wait_time
}
