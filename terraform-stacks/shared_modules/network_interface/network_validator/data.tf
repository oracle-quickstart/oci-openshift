# VCN validation
data "oci_core_vcn" "existing_vcn" {
  vcn_id = var.existing_vcn_id
}


# NSG lookup - Automatic discovery
data "oci_core_network_security_groups" "existing_lb_nsgs" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*lb.*"]
    regex  = true
  }
}

data "oci_core_network_security_groups" "existing_controlplane_nsgs" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*controlplane.*"]
    regex  = true
  }
}

data "oci_core_network_security_groups" "existing_compute_nsgs" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*compute.*"]
    regex  = true
  }
}

# Gateway lookups - Automatic discovery
data "oci_core_internet_gateways" "existing_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id
}

data "oci_core_service_gateways" "existing_sgw" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id
}

data "oci_core_nat_gateways" "existing_nat" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id
}

# Security Lists - Automatic discovery
data "oci_core_security_lists" "existing_private" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*private.*"]
    regex  = true
  }
}

data "oci_core_security_lists" "existing_public" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*public.*"]
    regex  = true
  }
}

# Route Tables - Automatic discovery
data "oci_core_route_tables" "existing_private_routes" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*private.*"]
    regex  = true
  }
}

data "oci_core_route_tables" "existing_public_routes" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.existing_vcn_id

  filter {
    name   = "display_name"
    values = [".*public.*"]
    regex  = true
  }
}

# NSG Security Rules - for validation and rule management
data "oci_core_network_security_group_security_rules" "existing_lb_rules" {
  network_security_group_id = data.oci_core_network_security_groups.existing_lb_nsgs.network_security_groups[0].id
}

data "oci_core_network_security_group_security_rules" "existing_controlplane_rules" {
  network_security_group_id = data.oci_core_network_security_groups.existing_controlplane_nsgs.network_security_groups[0].id
}

data "oci_core_network_security_group_security_rules" "existing_compute_rules" {
  network_security_group_id = data.oci_core_network_security_groups.existing_compute_nsgs.network_security_groups[0].id
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
