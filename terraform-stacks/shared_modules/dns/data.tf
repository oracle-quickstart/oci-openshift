data "oci_core_vcn_dns_resolver_association" "dns_resolver_association" {
  vcn_id = var.op_vcn_openshift_vcn
}

data "oci_dns_resolver" "dns_resolver" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.dns_resolver_association.dns_resolver_id
  scope       = "PRIVATE"
}
