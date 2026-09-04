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
