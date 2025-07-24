variable "use_existing_network" {
  type    = bool
  default = false
}

variable "existing_vcn_id" {
  type = string
}

variable "vcn_cidr" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "networking_compartment_ocid" {
  type = string
}

variable "vcn_dns_label" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_cidr_ocp" {
  type = string
}

variable "private_cidr_bare_metal" {
  type = string
}

variable "public_cidr" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}

variable "existing_private_ocp_subnet_id" {
  type = string
}

variable "existing_private_bare_metal_subnet_id" {
  type = string
}

variable "existing_public_subnet_id" {
  type = string
}
