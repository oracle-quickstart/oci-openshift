terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "boot_artifacts" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${var.cluster_name}-boot-artifacts"
  access_type    = "NoPublicAccess"
  defined_tags   = var.defined_tags
}

resource "oci_objectstorage_object" "rootfs" {
  count     = var.rootfs_file_path != "" ? 1 : 0
  namespace = data.oci_objectstorage_namespace.ns.namespace
  bucket    = oci_objectstorage_bucket.boot_artifacts.name
  object    = "agent.x86_64-rootfs.img"
  source    = var.rootfs_file_path
}

resource "oci_objectstorage_preauthrequest" "rootfs" {
  namespace   = data.oci_objectstorage_namespace.ns.namespace
  bucket      = oci_objectstorage_bucket.boot_artifacts.name
  name        = "${var.cluster_name}-rootfs-par"
  access_type = "ObjectRead"
  object_name = "agent.x86_64-rootfs.img"
  time_expires = timeadd(timestamp(), "${var.par_expiry_hours}h")

  lifecycle {
    ignore_changes = [time_expires]
  }
}
