terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.38.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.11.1"
    }
  }
}

# Home Region
variable "home_region" {
  type        = string
  description = "The home region of the tenancy."
}

variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}

# Openshift infrastructure compartment
variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment where you wish to create the OpenShift cluster."
}

# Openshift cluster name
variable "cluster_name" {
  type        = string
  description = "The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible. The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
}

variable "home_region_profile_name" {
  type        = string
  description = "The home region profile name configured in the ~/.oci/config"
}

# Home Region Terraform Provider
provider "oci" {
  alias               = "home"
  config_file_profile = var.home_region_profile_name
}

data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
  provider   = oci.home
}

# Defined tag namespace. Use to mark instance roles and configure instance policy
resource "oci_identity_tag_namespace" "openshift_tags" {
  compartment_id = var.compartment_ocid
  description    = "Used for track openshift related resources and policies"
  is_retired     = "false"
  name           = "openshift-${var.cluster_name}"
  provider       = oci.home
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
  provider = oci.home
}

resource "oci_identity_dynamic_group" "openshift_control_plane_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift control_plane nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='control_plane'}"
  name           = "${var.cluster_name}_control_plane_nodes"
  provider       = oci.home
}

resource "oci_identity_policy" "openshift_control_plane_nodes" {
  compartment_id = var.compartment_ocid
  description    = "OpenShift control_plane nodes instance principal"
  name           = "${var.cluster_name}_control_plane_nodes"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to use virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage load-balancers in compartment id ${var.compartment_ocid}",
  ]
  provider = oci.home
}

resource "oci_identity_dynamic_group" "openshift_compute_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift compute nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.openshift-${var.cluster_name}.instance-role.value='compute'}"
  name           = "${var.cluster_name}_compute_nodes"
  provider       = oci.home
}