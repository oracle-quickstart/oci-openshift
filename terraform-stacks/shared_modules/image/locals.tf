data "oci_core_compute_global_image_capability_schemas" "image_capability_schemas" {
}

locals {

  global_image_capability_schemas = data.oci_core_compute_global_image_capability_schemas.image_capability_schemas.compute_global_image_capability_schemas

  schema_firmware = {
    "Compute.Firmware" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = "UEFI_64",
      "values"         = ["UEFI_64"]
    })
  }

  schema_boot_volume_type = {
    "Storage.BootVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !var.is_control_plane_iscsi_type && !var.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_launch_mode = {
    "Compute.LaunchMode" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !var.is_control_plane_iscsi_type && !var.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "NATIVE",
      "values"         = ["NATIVE", "EMULATED", "PARAVIRTUALIZED", "CUSTOM"]
    })
  }
  schema_local_volume_data_type = {
    "Storage.LocalDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !var.is_control_plane_iscsi_type && !var.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_remote_volume_data_type = {
    "Storage.RemoteDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !var.is_control_plane_iscsi_type && !var.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_storage_iscsi_multipath_device_supported = {
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      "descriptorType" = "boolean",
      "source"         = "IMAGE",
      "defaultValue"   = var.is_control_plane_iscsi_type || var.is_compute_iscsi_type ? true : false
    })
  }
}
