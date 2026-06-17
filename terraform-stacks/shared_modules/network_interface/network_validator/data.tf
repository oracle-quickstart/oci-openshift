# VCN validation
data "oci_core_vcn" "existing_vcn" {
  vcn_id = var.existing_vcn_id
}

# --- Gateways ---
data "oci_core_internet_gateways" "lookup" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
}

data "oci_core_nat_gateways" "lookup" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
}

data "oci_core_service_gateways" "lookup" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
}

# --- NSGs ---
data "oci_core_network_security_groups" "lb" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*lb.*"]
    regex  = true
  }
}

data "oci_core_network_security_groups" "controlplane" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*controlplane.*"]
    regex  = true
  }
}

data "oci_core_network_security_groups" "compute" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*compute.*"]
    regex  = true
  }
}

# --- Security Lists & Route Tables ---
data "oci_core_security_lists" "private" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*private.*"]
    regex  = true
  }
}

data "oci_core_security_lists" "public" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*public.*"]
    regex  = true
  }
}

data "oci_core_route_tables" "private" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*private.*"]
    regex  = true
  }
}

data "oci_core_route_tables" "public" {
  for_each       = toset(local.network_lookup_compartments)
  compartment_id = each.value
  vcn_id         = var.existing_vcn_id
  filter {
    name   = "display_name"
    values = [".*public.*"]
    regex  = true
  }
}

data "oci_core_network_security_group_security_rules" "lb_rules" {
  network_security_group_id = try(local.found_lb_nsgs[0].id, "none")
}

data "oci_core_network_security_group_security_rules" "controlplane_rules" {
  network_security_group_id = try(local.found_controlplane_nsgs[0].id, "none")
}

data "oci_core_network_security_group_security_rules" "compute_rules" {
  network_security_group_id = try(local.found_compute_nsgs[0].id, "none")
}

# Subnet data sources for property validation
data "oci_core_subnet" "existing_private_ocp" {
  subnet_id = var.existing_private_ocp_subnet_id
}

data "oci_core_subnet" "existing_private_bare_metal" {
  subnet_id = var.existing_private_bare_metal_subnet_id
}

data "oci_core_subnet" "existing_public" {
  subnet_id = var.existing_public_subnet_id
}
