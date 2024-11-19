resource "oci_identity_dynamic_group" "openshift_control_plane_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift control_plane nodes"

  matching_rule = "all {instance.compartment.id='${var.compartment_ocid}', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}.value='control_plane', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_openshift_resource}.value='${var.openshift_tag_openshift_resource_value}'}"

  name         = "${var.cluster_name}_control_plane_nodes"
  defined_tags = var.defined_tags
}

resource "oci_identity_dynamic_group" "openshift_compute_nodes" {
  compartment_id = var.tenancy_ocid
  description    = "OpenShift compute nodes"
  matching_rule  = "all {instance.compartment.id='${var.compartment_ocid}', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}.value='compute', tag.${var.op_openshift_tag_namespace}.${var.op_openshift_tag_openshift_resource}.value='${var.openshift_tag_openshift_resource_value}'}"
  name           = "${var.cluster_name}_compute_nodes"
  defined_tags   = var.defined_tags
}
