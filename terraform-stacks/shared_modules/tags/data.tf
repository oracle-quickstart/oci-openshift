# Defined tag namespace. Use to mark instance roles and configure instance policy
data "oci_identity_tag_namespaces" "openshift_tag_namespace" {
  count          = var.use_existing_tags ? 1 : 0
  compartment_id = var.tag_namespace_compartment_ocid != "" ? var.tag_namespace_compartment_ocid : var.compartment_ocid
  state          = "ACTIVE"
  filter {
    name   = "name"
    values = [var.tag_namespace_name != "" ? var.tag_namespace_name : "openshift-${var.cluster_name}"]
    regex  = true
  }
}

data "oci_identity_tag" "openshift_tag_instance_role" {
  count            = var.use_existing_tags ? 1 : 0
  tag_name         = "instance-role"
  tag_namespace_id = data.oci_identity_tag_namespaces.openshift_tag_namespace[0].tag_namespaces[0].id
}

data "oci_identity_tag" "openshift_tag_boot_volume_type" {
  count            = var.use_existing_tags ? 1 : 0
  tag_name         = "boot-volume-type"
  tag_namespace_id = data.oci_identity_tag_namespaces.openshift_tag_namespace[0].tag_namespaces[0].id
}
