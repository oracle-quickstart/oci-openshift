resource "oci_core_image" "autoscaling_image" {
  count          = var.use_autoscaling_operator ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.image_name}-autoscaling-image"
  launch_mode    = "NATIVE"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.autoscaler_node_image_source_uri

    source_image_type = local.autoscaling_source_image_type
  }
  defined_tags = var.defined_tags

  lifecycle {
    precondition {
      condition     = can(regex("^https://objectstorage\\.[^/]+\\.[^/]+/(p/[^/]+/)?n/[^/]+/b/[^/]+/o/.+", trimspace(var.autoscaler_node_image_source_uri)))
      error_message = "The autoscaler_node_image_source_uri value must be an OCI Object Storage object or PAR URL when use_autoscaling_operator is enabled."
    }
  }
}

resource "oci_core_shape_management" "autoscaling_image_shape_mgmt" {
  count          = var.use_autoscaling_operator ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.autoscaling_image[0].id
  shape_name     = var.autoscaler_node_shape
}

resource "oci_core_compute_image_capability_schema" "autoscaling_image_capability_schema" {
  count                                               = var.use_autoscaling_operator ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.autoscaling_image[0].id
  schema_data                                         = merge(local.is_autoscaler_bm_shape ? local.schema_bare_metal : local.schema_vm)
  defined_tags                                        = var.defined_tags
}
