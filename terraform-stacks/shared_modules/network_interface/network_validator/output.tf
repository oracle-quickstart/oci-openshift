# VCN Details
output "vcn_details" {
  value = {
    vcn_id         = data.oci_core_vcn.existing_vcn.id
    compartment_id = data.oci_core_vcn.existing_vcn.compartment_id
    state          = data.oci_core_vcn.existing_vcn.state
    lookup_scopes  = local.network_lookup_compartments
  }
}

# Subnet Details
output "subnet_details" {
  value = {
    private_ocp_subnet = {
      id             = data.oci_core_subnet.existing_private_ocp.id
      compartment_id = data.oci_core_subnet.existing_private_ocp.compartment_id
    }
    private_bare_metal_subnet = {
      id             = data.oci_core_subnet.existing_private_bare_metal.id
      compartment_id = data.oci_core_subnet.existing_private_bare_metal.compartment_id
    }
    public_subnet = {
      id             = data.oci_core_subnet.existing_public.id
      compartment_id = data.oci_core_subnet.existing_public.compartment_id
    }
  }
}

# NSG Details
output "nsg_details" {
  description = "Discovered NSG information across VCN and Subnet compartments."
  value = {
    lb_nsg = {
      id      = try(local.found_lb_nsgs[0].id, null)
      matched = [for n in local.found_lb_nsgs : { id = n.id, name = n.display_name, compartment_id = n.compartment_id }]
    }
    controlplane_nsg = {
      id      = try(local.found_controlplane_nsgs[0].id, null)
      matched = [for n in local.found_controlplane_nsgs : { id = n.id, name = n.display_name, compartment_id = n.compartment_id }]
    }
    compute_nsg = {
      id      = try(local.found_compute_nsgs[0].id, null)
      matched = [for n in local.found_compute_nsgs : { id = n.id, name = n.display_name, compartment_id = n.compartment_id }]
    }
  }
}

# Security List Details
output "security_list_details" {
  value = {
    private_security_list = {
      id = try(
        flatten([for d in data.oci_core_security_lists.private : d.security_lists])[0].id, null
      )
      matched = [
        for sl in flatten([for d in data.oci_core_security_lists.private : d.security_lists]) :
        { id = sl.id, name = sl.display_name, compartment_id = sl.compartment_id }
      ]
    }
    public_security_list = {
      id = try(
        flatten([for d in data.oci_core_security_lists.public : d.security_lists])[0].id, null
      )
      matched = [
        for sl in flatten([for d in data.oci_core_security_lists.public : d.security_lists]) :
        { id = sl.id, name = sl.display_name, compartment_id = sl.compartment_id }
      ]
    }
  }
}
