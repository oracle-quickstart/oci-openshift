# full_path is the provider's own fully-qualified PAR URL. It derives the
# Object Storage host from the region, so it is correct in every realm without
# us supplying a realm domain. Verified in OC3 (oraclegovcloud.com) against
# provider 9.10.0: full_path matched our hand-built URL byte for byte.

output "boot_artifacts_base_url" {
  description = "PAR base URL for bootArtifactsBaseURL in agent-config.yaml. The agent installer appends /agent.x86_64-rootfs.img, so the object name is trimmed here."
  value = trimsuffix(
    oci_objectstorage_preauthrequest.rootfs.full_path,
    "/${oci_objectstorage_preauthrequest.rootfs.object_name}"
  )
}

output "iso_par_url" {
  description = "Full PAR URL to the agent ISO in Object Storage. Used as openshift_image_source_uri for the image module."
  value       = oci_objectstorage_preauthrequest.iso.full_path
}
