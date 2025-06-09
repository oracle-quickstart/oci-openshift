variable "zone_dns" {
  type = string
}

variable "enable_private_dns" {
  type = bool
}

variable "compartment_ocid" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}

variable "cluster_name" {
  type = string
}

variable "op_lb_openshift_api_int_lb_ip_addr" {
  type = string
}

variable "op_lb_openshift_api_lb_ip_addr" {
  type = string
}

variable "op_lb_openshift_apps_lb_ip_addr" {
  type = string
}

variable "op_vcn_openshift_vcn" {
  type = string
}
