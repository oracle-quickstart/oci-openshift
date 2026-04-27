locals {
  network_lookup_compartments = distinct([
    var.vcn_compartment_ocid,
    var.subnet_compartment_ocid
  ])
  found_igs  = flatten([for d in data.oci_core_internet_gateways.lookup : d.gateways])
  found_nats = flatten([for d in data.oci_core_nat_gateways.lookup : d.nat_gateways])
  found_sgws = flatten([for d in data.oci_core_service_gateways.lookup : d.service_gateways])

  found_lb_nsgs           = flatten([for d in data.oci_core_network_security_groups.lb : d.network_security_groups])
  found_controlplane_nsgs = flatten([for d in data.oci_core_network_security_groups.controlplane : d.network_security_groups])
  found_compute_nsgs      = flatten([for d in data.oci_core_network_security_groups.compute : d.network_security_groups])
}
