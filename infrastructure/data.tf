data "oci_identity_tenancy" "tenancy" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_regions" "regions" {
}

data "oci_identity_availability_domain" "availability_domain" {
  compartment_id = var.compartment_ocid
  ad_number      = "1"
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
  count = var.create_openshift_instance_pools ? var.control_plane_count : 0
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.control_plane_node[count.index].id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_primary_vnic" {
  count   = var.create_openshift_instance_pools && !local.is_control_plane_iscsi_type ? var.control_plane_count : 0
  vnic_id = data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments[count.index].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.control_plane_primary_vnic_attachments,oci_core_instance.control_plane_node]
}

data "oci_core_vnic" "control_plane_secondary_vnic" {
  count   = var.create_openshift_instance_pools && (local.is_control_plane_iscsi_type || local.is_compute_iscsi_type) ? var.control_plane_count : 0
  vnic_id = oci_core_vnic_attachment.control_plane_secondary_vnic_attachment[count.index].vnic_id

  depends_on = [oci_core_instance.control_plane_node]
}

data "oci_core_vnic_attachments" "compute_primary_vnic_attachments" {
  count = var.create_openshift_instance_pools ? var.compute_count : 0
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.compute_node[count.index].id

  depends_on = [oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_primary_vnic" {
  count   = var.create_openshift_instance_pools && !local.is_compute_iscsi_type ? var.compute_count : 0
  vnic_id = data.oci_core_vnic_attachments.compute_primary_vnic_attachments[count.index].vnic_attachments[0].vnic_id

  depends_on = [data.oci_core_vnic_attachments.compute_primary_vnic_attachments, oci_core_instance.compute_node]
}

data "oci_core_vnic" "compute_secondary_vnic" {
  count   = var.create_openshift_instance_pools && (local.is_control_plane_iscsi_type || local.is_compute_iscsi_type) ? var.compute_count : 0
  vnic_id = oci_core_vnic_attachment.compute_secondary_vnic_attachment[count.index].vnic_id

  depends_on = [oci_core_instance.compute_node]
}