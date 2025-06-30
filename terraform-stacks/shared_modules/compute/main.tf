terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}
# control plane nodes
resource "oci_core_instance" "control_plane_node" {
  for_each            = var.create_openshift_instances ? var.cp_node_map : {}
  compartment_id      = var.compartment_ocid
  availability_domain = each.value.ad_name
  fault_domain        = var.distribute_cp_instances_across_fds ? each.value.fault_domain : null
  display_name        = "${var.cluster_name}-cp-${each.value.index}"
  shape               = var.control_plane_shape

  defined_tags = {
    "${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}"         = "control_plane"
    "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
  }

  create_vnic_details {
    display_name              = "${var.cluster_name}-cp-${each.value.index}"
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    nsg_ids = [
      var.op_network_security_group_cluster_controlplane_nsg,
    ]
    subnet_id  = var.is_control_plane_iscsi_type ? var.op_subnet_private_bare_metal : var.op_subnet_private_ocp
    private_ip = each.value.index == 1 && !var.is_control_plane_iscsi_type && local.is_abi ? var.rendezvous_ip : ""
  }

  source_details {
    source_type             = "image"
    boot_volume_size_in_gbs = var.control_plane_boot_size
    boot_volume_vpus_per_gb = var.control_plane_boot_volume_vpus_per_gb
    source_id               = var.is_control_plane_iscsi_type ? var.op_image_openshift_image_native : var.op_image_openshift_image_paravirtualized
  }

  dynamic "shape_config" {
    for_each = var.is_control_plane_iscsi_type ? [] : [1]
    content {
      memory_in_gbs = var.control_plane_memory
      ocpus         = var.control_plane_ocpu
    }
  }

  metadata = {
    user_data = base64encode(file("${path.module}/userdata/iscsi-oci-configure-secondary-nic.sh"))
  }
}

# compute nodes
resource "oci_core_instance" "compute_node" {
  for_each            = var.create_openshift_instances ? var.compute_node_map : {}
  compartment_id      = var.compartment_ocid
  availability_domain = each.value.ad_name
  fault_domain        = var.distribute_compute_instances_across_fds ? each.value.fault_domain : null
  display_name        = "${var.cluster_name}-compute-${each.value.index}"
  shape               = var.compute_shape

  defined_tags = {
    "${var.op_openshift_tag_namespace}.${var.op_openshift_tag_instance_role}"         = "compute"
    "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
  }

  create_vnic_details {
    display_name              = "${var.cluster_name}-compute-${each.value.index}"
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    subnet_id                 = var.is_compute_iscsi_type ? var.op_subnet_private_bare_metal : var.op_subnet_private_ocp
    nsg_ids = [
      var.op_network_security_group_cluster_compute_nsg,
    ]
  }

  source_details {
    source_type             = "image"
    boot_volume_size_in_gbs = var.compute_boot_size
    boot_volume_vpus_per_gb = var.compute_boot_volume_vpus_per_gb
    source_id               = var.is_compute_iscsi_type ? var.op_image_openshift_image_native : var.op_image_openshift_image_paravirtualized
  }

  dynamic "shape_config" {
    for_each = var.is_compute_iscsi_type ? [] : [1] # Only include shape_config if apply_vm_shape is true
    content {
      memory_in_gbs = var.compute_memory
      ocpus         = var.compute_ocpu
    }
  }

  metadata = {
    user_data = base64encode(file("${path.module}/userdata/iscsi-oci-configure-secondary-nic.sh"))
  }
}
