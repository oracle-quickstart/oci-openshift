terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

// Skip paravirtualized image only when both cp and compute are BM
resource "oci_core_image" "openshift_image_paravirtualized" {
  count          = var.create_openshift_instances && (!var.is_control_plane_iscsi_type || !var.is_compute_iscsi_type) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.image_name}-paravirtualized"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
  defined_tags = var.defined_tags
}

// Skip native image only when both cp and compute are VM
resource "oci_core_image" "openshift_image_native" {
  count          = var.create_openshift_instances && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type) ? 1 : 0
  compartment_id = var.compartment_ocid
  display_name   = "${var.image_name}-native"
  launch_mode    = "NATIVE"

  image_source_details {
    source_type = "objectStorageUri"
    source_uri  = var.openshift_image_source_uri

    source_image_type = "QCOW2"
  }
  defined_tags = var.defined_tags
}


resource "oci_core_shape_management" "imaging_control_plane_shape" {
  count          = var.create_openshift_instances ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.is_control_plane_iscsi_type ? oci_core_image.openshift_image_native[0].id : oci_core_image.openshift_image_paravirtualized[0].id
  shape_name     = var.control_plane_shape
}

resource "oci_core_shape_management" "imaging_compute_shape" {
  count          = var.create_openshift_instances ? 1 : 0
  compartment_id = var.compartment_ocid
  image_id       = var.is_compute_iscsi_type ? oci_core_image.openshift_image_native[0].id : oci_core_image.openshift_image_paravirtualized[0].id
  shape_name     = var.compute_shape
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema_paravirtualized" {
  count                                               = var.create_openshift_instances && (!var.is_control_plane_iscsi_type || !var.is_compute_iscsi_type) ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image_paravirtualized[0].id
  schema_data                                         = merge(local.schema_vm)
  defined_tags                                        = var.defined_tags
}

resource "oci_core_compute_image_capability_schema" "openshift_image_capability_schema_native" {
  count                                               = var.create_openshift_instances && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type) ? 1 : 0
  compartment_id                                      = var.compartment_ocid
  compute_global_image_capability_schema_version_name = local.global_image_capability_schemas[0].current_version_name
  image_id                                            = oci_core_image.openshift_image_native[0].id
  schema_data                                         = merge(local.schema_bare_metal)
  defined_tags                                        = var.defined_tags
}
