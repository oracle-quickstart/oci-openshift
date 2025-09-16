output "compute_node_map" {
  value = local.compute_node_map
}

output "cp_node_map" {
  value = local.cp_node_map
}

output "ad_name" {
  value = local.availability_domains[0].name
}

output "node_distribution_summary" {
  description = "Summary of total node distribution across all Availability Domains"
  value = {
    control_plane = {
      total_nodes      = var.control_plane_count
      nodes_in_each_ad = local.cp_node_count_per_ad_map
      distribution     = local.compute_node_count_per_ad_map
    }
    compute = {
      total_nodes      = var.compute_count
      nodes_in_each_ad = local.compute_node_count_per_ad_map
      distribution     = local.compute_node_map
    }
  }
}

output "region_metadata" {
  value = local.region_metadata == "error" ? "" : jsonencode(local.region_metadata)
}
