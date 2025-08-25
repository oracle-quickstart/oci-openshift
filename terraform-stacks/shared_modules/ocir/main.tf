
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

# Fetch the only version of the oca listing
data "oci_marketplace_listing_packages" "marketplace_listing_packages" {
  listing_id = "ocid1.mktpublisting.oc1.phx.amaaaaaabg7vt6ia6vyockkduxg2jvwmxzef7nliwilshjavyjrybs66g57q"
}

locals {
  oca_version = try(data.oci_marketplace_listing_packages.marketplace_listing_packages.listing_packages[0].package_version, "NA")

  all_images = flatten([
    for collection in data.oci_artifacts_container_images.oca_container_images.container_image_collection : collection.items
  ])

  filtered_images = [
    for img in local.all_images :
    img if can(img.display_name) && length(regexall(local.oca_version, img.display_name)) > 0
  ]

  namespace = data.oci_objectstorage_namespace.namespace_details.namespace

  image_pull_command = "${lower(var.region)}.ocir.io/${local.namespace}/${try(local.filtered_images[0].display_name, "no-image-found")}"
}
