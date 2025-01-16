resource "oci_core_subnet" "private" {
  cidr_block     = var.private_cidr
  display_name   = "private"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id
  security_list_ids = [
    oci_core_security_list.private.id,
  ]
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  defined_tags               = var.defined_tags
}

resource "oci_core_subnet" "private2" {
  cidr_block     = var.private_cidr_2
  display_name   = "private_two"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.openshift_vcn.id
  route_table_id = oci_core_route_table.private_routes.id
  security_list_ids = [
    oci_core_security_list.private.id,
  ]

  dns_label                  = "private2"
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
