
terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

data "oci_objectstorage_namespace" "namespace_details" {
  compartment_id = var.compartment_ocid
}

data "oci_artifacts_container_images" "oca_container_images" {
  compartment_id  = var.compartment_ocid
  repository_name = var.oca_repo_name
}

# Fetch the only version of the oca listing. Listing OCIDs are realm-scoped,
# so this is configurable. When the listing does not exist in the realm, the
# data source returns no packages rather than an error.
data "oci_marketplace_listing_packages" "marketplace_listing_packages" {
  listing_id = var.oca_marketplace_listing_id
}

locals {
  oca_version = try(data.oci_marketplace_listing_packages.marketplace_listing_packages.listing_packages[0].package_version, "NA")

  all_images = flatten([
    for collection in data.oci_artifacts_container_images.oca_container_images.container_image_collection : collection.items
  ])

  # With no listing version there is nothing to match. Using "NA" as the
  # pattern would match any image whose name happens to contain it.
  filtered_images = local.oca_version == "NA" ? [] : [
    for img in local.all_images :
    img if can(img.display_name) && length(regexall(local.oca_version, img.display_name)) > 0
  ]

  namespace = data.oci_objectstorage_namespace.namespace_details.namespace

  image_pull_command = length(local.filtered_images) > 0 ? "${lower(var.region)}.ocir.io/${local.namespace}/${local.filtered_images[0].display_name}" : ""
}
