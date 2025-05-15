output "op_image_openshift_image_paravirtualized" {
  value = try(oci_core_image.openshift_image_paravirtualized[0].id, null)
}

output "op_image_openshift_image_native" {
  value = try(oci_core_image.openshift_image_native[0].id, null)
}
