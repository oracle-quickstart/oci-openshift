output "op_image_openshift_image" {
  value = try(oci_core_image.openshift_image[0].id, null)
}
