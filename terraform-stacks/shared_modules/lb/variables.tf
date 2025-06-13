variable "enable_public_apps_lb" {
  type = bool
}

variable "enable_public_api_lb" {
  type = bool
}

variable "compartment_ocid" {
  type = string
}

variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  type = number
}

variable "load_balancer_shape_details_minimum_bandwidth_in_mbps" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}

variable "op_subnet_private_ocp" {
  type = string
}

variable "op_subnet_public" {
  type = string
}

variable "op_network_security_group_cluster_lb_nsg" {
  type = string
}
