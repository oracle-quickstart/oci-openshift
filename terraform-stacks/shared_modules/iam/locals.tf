locals {
  need_vcn_policy = (
    var.vcn_compartment_ocid != null &&
    var.compartment_ocid != var.vcn_compartment_ocid
  )

  need_subnet_policy = (
    var.subnet_compartment_ocid != null &&
    var.compartment_ocid != var.subnet_compartment_ocid &&
    var.subnet_compartment_ocid != var.vcn_compartment_ocid
  )
}
