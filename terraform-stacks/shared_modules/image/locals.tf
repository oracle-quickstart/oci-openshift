data "oci_core_compute_global_image_capability_schemas" "image_capability_schemas" {
}

locals {

  global_image_capability_schemas = data.oci_core_compute_global_image_capability_schemas.image_capability_schemas.compute_global_image_capability_schemas
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
      defaultValue   = true
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
