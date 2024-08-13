locals {
  region_map = {
  for r in data.oci_identity_regions.regions.regions :
  r.key => r.name
  }

  home_region = local.region_map[data.oci_identity_tenancy.tenancy.home_region_key]

  availability_domains = data.oci_identity_availability_domains.ads.availability_domains
  total_ads            = length(local.availability_domains)

  # Calculate base nodes per AD
  cp_nodes_per_ad      = floor(var.control_plane_count / local.total_ads)
  compute_nodes_per_ad = floor(var.compute_count / local.total_ads)

  # Calculate extra nodes to distribute
  cp_extra_nodes      = var.control_plane_count % local.total_ads
  compute_extra_nodes = var.compute_count % local.total_ads

  # Create a map for node count per AD in round-robin fashion
  cp_node_count_per_ad_map = {
  for i in range(local.total_ads) :
  local.availability_domains[i].name => local.cp_nodes_per_ad + (i < local.cp_extra_nodes ? 1 : 0)
  }
  compute_node_count_per_ad_map = {
  for i in range(local.total_ads) :
  local.availability_domains[i].name => local.compute_nodes_per_ad + (i < local.compute_extra_nodes ? 1 : 0)
  }

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
      "defaultValue"   = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_launch_mode = {
    "Compute.LaunchMode" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "NATIVE",
      "values"         = ["NATIVE", "EMULATED", "PARAVIRTUALIZED", "CUSTOM"]
    })
  }
  schema_local_volume_data_type = {
    "Storage.LocalDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_remote_volume_data_type = {
    "Storage.RemoteDataVolumeType" = jsonencode({
      "descriptorType" = "enumstring",
      "source"         = "IMAGE",
      "defaultValue"   = !local.is_control_plane_iscsi_type && !local.is_compute_iscsi_type ? "PARAVIRTUALIZED" : "ISCSI",
      "values"         = ["ISCSI", "SCSI", "IDE", "PARAVIRTUALIZED"]
    })
  }
  schema_storage_iscsi_multipath_device_supported = {
    "Storage.Iscsi.MultipathDeviceSupported" = jsonencode({
      "descriptorType" = "boolean",
      "source"         = "IMAGE",
      "defaultValue"   = local.is_control_plane_iscsi_type || local.is_compute_iscsi_type ? true : false
    })
  }

  is_control_plane_iscsi_type = can(regex("^BM\\..*$", var.control_plane_shape))
  is_compute_iscsi_type       = can(regex("^BM\\..*$", var.compute_shape))
  is_mix_type              = var.control_plane_shape != var.compute_shape

  common_defined_tags = {
    "openshift-${var.cluster_name}.openshift-resource" = "openshift-resource"
  }
}