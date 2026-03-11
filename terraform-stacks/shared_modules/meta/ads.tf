
terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_identity_fault_domains" "fds" {
  for_each            = toset([for ad in local.availability_domains : ad.name])
  availability_domain = each.value
  compartment_id      = var.compartment_ocid
}

locals {
  availability_domains = data.oci_identity_availability_domains.ads.availability_domains

  cp_ads      = var.distribute_cp_instances_across_ads ? length(local.availability_domains) : 1
  compute_ads = var.distribute_compute_instances_across_ads ? length(local.availability_domains) : 1

  # Get FDs for each AD
  fault_domains = {
    for ad in local.availability_domains : ad.name => data.oci_identity_fault_domains.fds[ad.name].fault_domains
  }


  # Calculate base nodes per AD
  cp_nodes_per_ad      = floor(var.control_plane_count / local.cp_ads)
  compute_nodes_per_ad = floor(var.compute_count / local.compute_ads)

  # Calculate extra nodes to distribute
  cp_extra_nodes      = var.control_plane_count % local.cp_ads
  compute_extra_nodes = var.compute_count % local.compute_ads

  # This will extract just the number at the end after "AD-"
  starting_ad_index_cp      = var.starting_ad_name_cp != null && var.starting_ad_name_cp != "" ? (regex("AD-([0-9]+)$", var.starting_ad_name_cp)[0]) - 1 : 0 # Subtract 1 because AD indices typically start from 1
  starting_ad_index_compute = var.starting_ad_name_compute != null && var.starting_ad_name_compute != "" ? (regex("AD-([0-9]+)$", var.starting_ad_name_compute)[0]) - 1 : 0

  # FD starting index
  starting_fd_index_cp = (
    !var.distribute_cp_instances_across_ads &&
    var.distribute_cp_instances_across_fds &&
    var.starting_ad_name_cp != null &&
    var.starting_fd_name_cp != null
    ) ? try(
    index(
      [for fd in local.fault_domains[var.starting_ad_name_cp] : fd.name],
      var.starting_fd_name_cp
    ),
    0
  ) : 0

  starting_fd_index_compute = (
    !var.distribute_compute_instances_across_ads &&
    var.distribute_compute_instances_across_fds &&
    var.starting_ad_name_compute != null &&
    var.starting_fd_name_compute != null
    ) ? try(
    index(
      [for fd in local.fault_domains[var.starting_ad_name_compute] : fd.name],
      var.starting_fd_name_compute
    ),
    0
  ) : 0

  # Create a map for node count per AD in round-robin fashion starting from AD specified from user
  cp_node_count_per_ad_map = {
    for i in range(local.cp_ads) :
    local.availability_domains[var.distribute_cp_instances_across_ads ?
      (i + local.starting_ad_index_cp) % length(local.availability_domains) :
    local.starting_ad_index_cp].name => local.cp_nodes_per_ad + (i < local.cp_extra_nodes ? 1 : 0)
  }

  compute_node_count_per_ad_map = {
    for i in range(local.compute_ads) :
    local.availability_domains[var.distribute_compute_instances_across_ads ?
      (i + local.starting_ad_index_compute) % length(local.availability_domains) :
    local.starting_ad_index_compute].name => local.compute_nodes_per_ad + (i < local.compute_extra_nodes ? 1 : 0)
  }

  cp_node_count_per_ad_flattened = flatten([
    for ad_name, count in local.cp_node_count_per_ad_map : [
      for i in range(count) : {
        ad_name = ad_name
        fault_domain = var.distribute_cp_instances_across_fds ? local.fault_domains[ad_name][
          (i + (var.distribute_cp_instances_across_ads ? 0 : local.starting_fd_index_cp))
          % length(local.fault_domains[ad_name])
        ].name : var.starting_fd_name_cp
      }
    ]
  ])

  compute_node_count_per_ad_flattened = flatten([
    for ad_name, count in local.compute_node_count_per_ad_map : [
      for i in range(count) : {
        ad_name = ad_name
        fault_domain = var.distribute_compute_instances_across_fds ? local.fault_domains[ad_name][
          (i + (var.distribute_compute_instances_across_ads ? 0 : local.starting_fd_index_compute))
          % length(local.fault_domains[ad_name])
        ].name : var.starting_fd_name_compute
      }
    ]
  ])

  cp_node_map = {
    for idx, val in local.cp_node_count_per_ad_flattened :
    idx => {
      ad_name      = val.ad_name
      fault_domain = val.fault_domain
      index        = idx + 1 + var.current_cp_count
    }
  }

  compute_node_map = {
    for idx, val in local.compute_node_count_per_ad_flattened :
    idx => {
      ad_name      = val.ad_name
      fault_domain = val.fault_domain
      index        = idx + 1 + var.current_compute_count
    }
  }

}
