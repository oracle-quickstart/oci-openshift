resource "oci_identity_policy" "policy_openshift_control_plane_nodes" {
  compartment_id = var.compartment_ocid
  description    = "OpenShift control_plane nodes instance principal"
  name           = "${var.cluster_name}_control_plane_nodes"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage volume-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage load-balancers in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage objects in compartment id ${var.compartment_ocid}",
  ]
  defined_tags = var.defined_tags
}

resource "oci_identity_policy" "policy_openshift_control_plane_nodes_tags" {
  compartment_id = var.tenancy_ocid
  description    = "Give OpenShift control_plane nodes access to use tag-namespaces for cluster resources"
  name           = "${var.cluster_name}_control_plane_nodes_tags"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to use tag-namespaces in tenancy",
  ]
  defined_tags = var.defined_tags
}

resource "oci_identity_policy" "policy_openshift_control_plane_nodes_networking" {
  count          = var.compartment_ocid != var.networking_compartment_ocid && var.networking_compartment_ocid != null ? 1 : 0
  compartment_id = var.networking_compartment_ocid
  description    = "OpenShift control_plane nodes network access"
  name           = "${var.cluster_name}_control_plane_nodes_networking_access_policy"
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage security-lists in compartment id ${var.networking_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.openshift_control_plane_nodes.name} to manage virtual-network-family in compartment id ${var.networking_compartment_ocid}",
  ]
  defined_tags = var.defined_tags
}
