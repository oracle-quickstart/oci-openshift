check "vcn_availability" {
  assert {
    condition     = data.oci_core_vcn.existing_vcn.state == "AVAILABLE"
    error_message = "❌ VCN State Error: VCN ${var.existing_vcn_id} is not in AVAILABLE state. Current state: ${data.oci_core_vcn.existing_vcn.state}."
  }
}

check "required_gateways" {
  assert {
    condition     = length(local.found_igs) > 0
    error_message = "❌ Missing Internet Gateway: No Internet Gateway found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires an Internet Gateway for external connectivity."
  }

  assert {
    condition     = length(local.found_sgws) > 0
    error_message = "❌ Missing Service Gateway: No Service Gateway found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires a Service Gateway for OCI service access."
  }

  assert {
    condition     = length(local.found_nats) > 0
    error_message = "❌ Missing NAT Gateway: No NAT Gateway found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires a NAT Gateway for outbound internet access."
  }
}

check "required_nsgs" {
  assert {
    condition     = length(local.found_lb_nsgs) > 0
    error_message = "❌ Missing Load Balancer NSG: No NSG with *lb* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires load balancer NSGs."
  }

  assert {
    condition     = length(local.found_controlplane_nsgs) > 0
    error_message = "❌ Missing Control Plane NSG: No NSG with *controlplane* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires control plane NSGs."
  }

  assert {
    condition     = length(local.found_compute_nsgs) > 0
    error_message = "❌ Missing Compute NSG: No NSG with *compute* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}. OpenShift requires compute NSGs."
  }
}

check "required_security_lists" {
  assert {
    condition     = length(flatten([for d in data.oci_core_security_lists.private : d.security_lists])) > 0
    error_message = "❌ Missing Private Security List: No security list with *private* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}."
  }

  assert {
    condition     = length(flatten([for d in data.oci_core_security_lists.public : d.security_lists])) > 0
    error_message = "❌ Missing Public Security List: No security list with *public* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}."
  }
}

check "required_route_tables" {
  assert {
    condition     = length(flatten([for d in data.oci_core_route_tables.private : d.route_tables])) > 0
    error_message = "❌ Missing Private Route Table: No route table with *private* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}."
  }

  assert {
    condition     = length(flatten([for d in data.oci_core_route_tables.public : d.route_tables])) > 0
    error_message = "❌ Missing Public Route Table: No route table with *public* pattern found in VCN ${var.existing_vcn_id} in compartments ${join(", ", local.network_lookup_compartments)}."
  }
}

check "subnet_configurations" {
  assert {
    condition     = data.oci_core_subnet.existing_private_ocp.state == "AVAILABLE"
    error_message = "❌ Subnet State Error: Private OCP subnet ${var.existing_private_ocp_subnet_id} is not in AVAILABLE state. Current state: ${data.oci_core_subnet.existing_private_ocp.state}."
  }

  assert {
    condition     = data.oci_core_subnet.existing_private_bare_metal.state == "AVAILABLE"
    error_message = "❌ Subnet State Error: Private bare metal subnet ${var.existing_private_bare_metal_subnet_id} is not in AVAILABLE state. Current state: ${data.oci_core_subnet.existing_private_bare_metal.state}."
  }

  assert {
    condition     = data.oci_core_subnet.existing_public.state == "AVAILABLE"
    error_message = "❌ Subnet State Error: Public subnet ${var.existing_public_subnet_id} is not in AVAILABLE state. Current state: ${data.oci_core_subnet.existing_public.state}."
  }

  assert {
    condition     = data.oci_core_subnet.existing_private_ocp.prohibit_public_ip_on_vnic == true
    error_message = "❌ Private Subnet VNIC Error: Private OCP subnet must prohibit public IPs on VNICs for security."
  }

  assert {
    condition     = data.oci_core_subnet.existing_private_bare_metal.prohibit_public_ip_on_vnic == true
    error_message = "❌ Private Subnet VNIC Error: Private bare metal subnet must prohibit public IPs on VNICs."
  }

  assert {
    condition     = data.oci_core_subnet.existing_public.prohibit_public_ip_on_vnic == false
    error_message = "❌ Public Subnet VNIC Error: Public subnet must allow public IPs on VNICs for load balancer functionality."
  }
}

check "security_rules" {
  assert {
    condition     = try(length(data.oci_core_network_security_group_security_rules.lb_rules.security_rules), 0) > 0
    error_message = "❌ Security Rule Error: LB NSG not found or contains no rules."
  }

  assert {
    condition     = try(length(data.oci_core_network_security_group_security_rules.controlplane_rules.security_rules), 0) > 0
    error_message = "❌ Security Rule Error: Control Plane NSG not found or contains no rules."
  }

  assert {
    condition     = try(length(data.oci_core_network_security_group_security_rules.compute_rules.security_rules), 0) > 0
    error_message = "❌ Security Rule Error: Compute NSG not found or contains no rules."
  }
}
