variable "compartment_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "existing_vcn_id" {
  type = string
}

variable "existing_private_ocp_subnet_id" {
  type = string
}

variable "networking_compartment_ocid" {
  type    = string
  default = ""
}
