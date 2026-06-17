data "oci_core_compute_global_image_capability_schemas" "image_capability_schemas" {
}

locals {

  global_image_capability_schemas = data.oci_core_compute_global_image_capability_schemas.image_capability_schemas.compute_global_image_capability_schemas
  autoscaling_source_image_type   = "QCOW2"
  is_autoscaler_bm_shape          = can(regex("^BM\\.", var.autoscaler_node_shape))
  schema_bare_metal = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "ISCSI"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "NATIVE"
      values         = ["NATIVE", "EMULATED", "PARAVIRTUALIZED", "CUSTOM"]
    })
    "Storage.LocalDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "ISCSI"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Storage.RemoteDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "ISCSI"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = false
    })
  }

  schema_vm = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Compute.LaunchMode" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["NATIVE", "EMULATED", "PARAVIRTUALIZED", "CUSTOM"]
    })
    "Storage.LocalDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Storage.RemoteDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = false
    })
  }
}
