locals {
  val_openshift_tag_namespace = var.use_existing_tags ? data.oci_identity_tag_namespaces.openshift_tag_namespace[0].tag_namespaces[0].name : oci_identity_tag_namespace.openshift_tag_namespace[0].name

  val_openshift_tag_instance_role = var.use_existing_tags ? data.oci_identity_tag.openshift_tag_instance_role[0].name : oci_identity_tag.openshift_tag_instance_role[0].name

  val_openshift_tag_boot_volume_type = var.use_existing_tags ? data.oci_identity_tag.openshift_tag_boot_volume_type[0].name : oci_identity_tag.openshift_tag_boot_volume_type[0].name
}

output "op_openshift_tag_namespace" {
  value = local.val_openshift_tag_namespace
}

output "op_openshift_tag_instance_role" {
  value = local.val_openshift_tag_instance_role
}

output "op_openshift_tag_boot_volume_type" {
  value = local.val_openshift_tag_boot_volume_type
}

output "wait_for_tag_consistency" {
  value = time_sleep.wait_for_new_tag_consistency
}
