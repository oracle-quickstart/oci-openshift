data "oci_core_vnic_attachments" "control_plane_primary_vnic_attachments" {
  for_each       = var.create_openshift_instances ? var.cp_node_map : {}
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.control_plane_node[each.key].id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_primary_vnic" {
  for_each = var.create_openshift_instances && !var.is_control_plane_iscsi_type ? var.cp_node_map : {}
  vnic_id  = data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments[each.key].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments, oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_secondary_vnic" {
  for_each = var.create_openshift_instances && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type) ? var.cp_node_map : {}
  vnic_id  = oci_core_vnic_attachment.control_plane_secondary_vnic_attachment[each.key].vnic_id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic_attachments" "compute_primary_vnic_attachments" {
  for_each       = var.create_openshift_instances ? var.compute_node_map : {}
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.compute_node[each.key].id

  depends_on = [oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_primary_vnic" {
  for_each = var.create_openshift_instances && !var.is_compute_iscsi_type ? var.compute_node_map : {}
  vnic_id  = data.oci_core_vnic_attachments.compute_primary_vnic_attachments[each.key].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.compute_primary_vnic_attachments, oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_secondary_vnic" {
  for_each = var.create_openshift_instances && (var.is_control_plane_iscsi_type || var.is_compute_iscsi_type) ? var.compute_node_map : {}
  vnic_id  = oci_core_vnic_attachment.compute_secondary_vnic_attachment[each.key].vnic_id

  depends_on = [oci_core_instance.compute_node]
}
