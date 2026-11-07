output "image_pull_command" {
  value = local.image_pull_command

  # Fail the plan rather than render an Oracle Cloud Agent DaemonSet whose
  # image does not exist.
  precondition {
    condition     = local.image_pull_command != ""
    error_message = "use_oracle_cloud_agent is true, but no Oracle Cloud Agent image was found. Either the Marketplace listing ${var.oca_marketplace_listing_id} returned no package version in this realm, or the OCIR repository '${var.oca_repo_name}' has no image matching it (resolved version: ${local.oca_version}). Accept the listing and export its image to that repository. Listing OCIDs are realm-specific: outside the commercial realm, set oca_marketplace_listing_id to the listing in that realm's Marketplace, if one exists."
  }
}
