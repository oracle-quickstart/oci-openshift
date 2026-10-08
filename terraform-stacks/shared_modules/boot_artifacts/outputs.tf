output "boot_artifacts_base_url" {
  description = "PAR base URL for bootArtifactsBaseURL in agent-config.yaml. The agent installer appends /agent.x86_64-rootfs.img to this URL."
  value = format("https://objectstorage.%s.%s%s",
    var.region,
    var.realm_domain,
    trimsuffix(
      oci_objectstorage_preauthrequest.rootfs.access_uri,
      "/${oci_objectstorage_preauthrequest.rootfs.object_name}"
    )
  )
}

output "iso_par_url" {
  description = "Full PAR URL to the agent ISO in Object Storage. Used as openshift_image_source_uri for the image module."
  value = format("https://objectstorage.%s.%s%s",
    var.region,
    var.realm_domain,
    oci_objectstorage_preauthrequest.iso.access_uri
  )
}
