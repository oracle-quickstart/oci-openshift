locals {
  openshift_resource_attribution_namespace = data.oci_identity_tag_namespaces.openshift_tag_namespace_attribution.tag_namespaces[0].name
  openshift_resource_attribution_key       = data.oci_identity_tag.openshift_tag_openshift_resource.name
}

output "openshift_resource_attribution_tag" {
  value = {
    "${local.openshift_resource_attribution_namespace}.${local.openshift_resource_attribution_key}" = var.openshift_attribution_tag_value

  }
}
