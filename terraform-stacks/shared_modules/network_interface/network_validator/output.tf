# VCN Details
output "vcn_details" {
  value = {
    vcn_id = data.oci_core_vcn.existing_vcn.id
  }
}

# Subnet Details
output "subnet_details" {
  value = {
    private_ocp_subnet = {
      id = data.oci_core_subnet.existing_private_ocp.id
    }
    private_bare_metal_subnet = {
      id = data.oci_core_subnet.existing_private_bare_metal.id
    }
    public_subnet = {
      id = data.oci_core_subnet.existing_public.id
    }
  }
}

# NSG Details
output "nsg_details" {
  value = {
    lb_nsg = {
      id = data.oci_core_network_security_groups.existing_lb_nsgs.network_security_groups[0].id
    }
    controlplane_nsg = {
      id = data.oci_core_network_security_groups.existing_controlplane_nsgs.network_security_groups[0].id
    }
    compute_nsg = {
      id = data.oci_core_network_security_groups.existing_compute_nsgs.network_security_groups[0].id
    }
  }
}

# Security List Details
output "security_list_details" {
  value = {
    private_security_list = {
      id = data.oci_core_security_lists.existing_private.security_lists[0].id
    }
    public_security_list = {
      id = data.oci_core_security_lists.existing_public.security_lists[0].id
    }
  }
}
