resource "oci_core_vnic_attachment" "control_plane_secondary_vnic_attachment" {
  for_each = var.create_openshift_instances && var.is_control_plane_iscsi_type ? var.cp_node_map : {}
  #Required
  create_vnic_details {
    #Optional
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    defined_tags = {
      "${var.op_openshift_tag_namespace}.${var.op_openshift_tag_boot_volume_type}"      = "ISCSI"
      "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
    }
    display_name   = "vnic_opc"
    hostname_label = oci_core_instance.control_plane_node[each.key].display_name
    nsg_ids        = [var.op_network_security_group_cluster_controlplane_nsg, ] #tbd
    subnet_id      = var.op_subnet_private_opc
    private_ip     = each.value.index == 1 && var.is_control_plane_iscsi_type && local.is_abi ? var.rendezvous_ip : ""
  }
  instance_id = oci_core_instance.control_plane_node[each.key].id

  #Optional
  display_name = "vnic_opc"
  nic_index    = 1
}

resource "oci_core_vnic_attachment" "compute_secondary_vnic_attachment" {
  for_each = var.create_openshift_instances && var.is_compute_iscsi_type ? var.compute_node_map : {}
  #Required
  create_vnic_details {

    #Optional
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    defined_tags = {
      "${var.op_openshift_tag_namespace}.${var.op_openshift_tag_boot_volume_type}"      = "ISCSI"
      "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
    }
    display_name   = "vnic_opc"
    hostname_label = oci_core_instance.compute_node[each.key].display_name
    nsg_ids        = [var.op_network_security_group_cluster_compute_nsg, ]
    subnet_id      = var.op_subnet_private_opc
  }
  instance_id = oci_core_instance.compute_node[each.key].id

  #Optional
  display_name = "vnic_opc"
  nic_index    = 1
}
