data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "regions" {
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_compute_global_image_capability_schemas" "image_capability_schemas" {
}

data "oci_core_services" "oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_vcn_dns_resolver_association" "dns_resolver_association" {
  vcn_id     = oci_core_vcn.openshift_vcn.id
  depends_on = [time_sleep.wait_180_seconds]
}

data "oci_dns_resolver" "dns_resolver" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.dns_resolver_association.dns_resolver_id
  scope       = "PRIVATE"
}

data "oci_core_vnic_attachments" "control_plane_primary_vnic_attachments" {
  for_each       = var.create_openshift_instances ? local.cp_node_map : {}
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.control_plane_node[each.key].id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_primary_vnic" {
  for_each = var.create_openshift_instances && !local.is_control_plane_iscsi_type ? local.cp_node_map : {}
  vnic_id  = data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments[each.key].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments, oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_secondary_vnic" {
  for_each = var.create_openshift_instances && (local.is_control_plane_iscsi_type || local.is_compute_iscsi_type) ? local.cp_node_map : {}
  vnic_id  = oci_core_vnic_attachment.control_plane_secondary_vnic_attachment[each.key].vnic_id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic_attachments" "compute_primary_vnic_attachments" {
  for_each       = var.create_openshift_instances ? local.compute_node_map : {}
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.compute_node[each.key].id

  depends_on = [oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_primary_vnic" {
  for_each = var.create_openshift_instances && !local.is_compute_iscsi_type ? local.compute_node_map : {}
  vnic_id  = data.oci_core_vnic_attachments.compute_primary_vnic_attachments[each.key].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.compute_primary_vnic_attachments, oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_secondary_vnic" {
  for_each = var.create_openshift_instances && (local.is_control_plane_iscsi_type || local.is_compute_iscsi_type) ? local.compute_node_map : {}
  vnic_id  = oci_core_vnic_attachment.compute_secondary_vnic_attachment[each.key].vnic_id

  depends_on = [oci_core_instance.compute_node]
}
