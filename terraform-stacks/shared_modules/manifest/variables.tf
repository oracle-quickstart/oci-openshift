variable "compartment_ocid" {
  type = string
}

variable "oci_driver_version" {
  type = string

  validation {
    condition     = contains(["v1.25.0", "v1.30.0", "v1.30.0-RWX-LA"], var.oci_driver_version)
    error_message = "The oci_driver_version must correspond to a folder in oci-openshift/custom_manifests/oci-ccm-csi-drivers/"
  }
}


variable "op_vcn_openshift_vcn" {
  type = string
}

variable "op_subnet" {
  type = string
}

variable "op_security_list" {
  type = string
}
