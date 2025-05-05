resource "oci_core_subnet" "private_opc" {
  cidr_block     = var.private_cidr_opc
  display_name   = "private_opc"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id
  security_list_ids = [
    oci_core_security_list.private.id,
  ]
  dns_label                  = "privateopc"
  prohibit_public_ip_on_vnic = true
  defined_tags               = var.defined_tags
}

resource "oci_core_subnet" "private_bare_metal" {
  cidr_block     = var.private_cidr_bare_metal
  display_name   = "private_bare_metal"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id
  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "privatebm"
  prohibit_public_ip_on_vnic = true
  defined_tags               = var.defined_tags
}

resource "oci_core_subnet" "public" {
  cidr_block     = var.public_cidr
  display_name   = "public"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.public_routes.id
  security_list_ids = [
    oci_core_security_list.public.id,
  ]
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  defined_tags               = var.defined_tags
}
