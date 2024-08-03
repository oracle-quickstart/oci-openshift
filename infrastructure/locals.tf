locals {
  region_map = {
  for r in data.oci_identity_regions.regions.regions :
  r.key => r.name
  }

  home_region = local.region_map[data.oci_identity_tenancy.tenancy.home_region_key]

  all_protocols                   = "all"
  anywhere                        = "0.0.0.0/0"
  pool_formatter_id               = join("", ["$", "{launchCount}"])


  global_image_capability_schemas = data.oci_core_compute_global_image_capability_schemas.image_capability_schemas.compute_global_image_capability_schemas
  image_schema_data = {
    "Compute.Firmware" = "{\"values\": [\"UEFI_64\"],\"defaultValue\": \"UEFI_64\",\"descriptorType\": \"enumstring\",\"source\": \"IMAGE\"}"
  }
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
      "defaultValue"   = local.is_vm_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_launch_mode = {
    "Compute.LaunchMode" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = local.is_vm_type ? "PARAVIRTUALIZED" : "NATIVE",
      "values"         = ["NATIVE", "EMULATED", "PARAVIRTUALIZED", "CUSTOM"]
    })
  }
  schema_local_volume_data_type = {
    "Storage.LocalDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = local.is_vm_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_remote_volume_data_type = {
    "Storage.RemoteDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = local.is_vm_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_storage_iscsi_multipath_device_supported = {
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      "descriptorType" = "boolean",
      "source"         = "IMAGE",
      "defaultValue"   = local.is_vm_type ? false : true
    })
  }

  is_vm_type = can(regex("^VM\\..*$", var.control_plane_shape)) && can(regex("^VM\\..*$", var.control_plane_shape))
  is_mix_type = var.compute_shape != var.control_plane_shape
}