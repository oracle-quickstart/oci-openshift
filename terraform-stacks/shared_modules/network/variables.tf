variable "vcn_cidr" {
  type = string
}

variable "compartment_ocid" {
  type = string
}

variable "vcn_dns_label" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_cidr" {
  type = string
}

variable "private_cidr_2" {
  type = string
}

variable "public_cidr" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}
