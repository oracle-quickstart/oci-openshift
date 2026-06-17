variable "compartment_ocid" { type = string }
variable "region" { type = string }
variable "tenancy_ocid" { type = string }
variable "op_vcn_id" { type = string }
variable "op_subnet_private_ocp" { type = string }
variable "op_network_security_group_cluster_lb_nsg" { type = string }
variable "op_lb_openshift_api_lb" { type = string }
variable "op_lb_openshift_api_lb_ip_addr" { type = string }
variable "capi_version" {
  type    = string
  default = "v1.12.3"
}

variable "capoci_version" {
  type    = string
  default = "v0.24.0"
}

variable "cluster_network_cidr_block" {
  type    = string
  default = "10.128.0.0/14"
}

variable "service_network_cidr_block" {
  type    = string
  default = "172.30.0.0/16"
}

variable "autoscaler_defined_tags_namespace" {
  type    = string
  default = ""
}

variable "bare_metal_subnet_id" { type = string }
variable "bare_metal_subnet_name" { type = string }
variable "ocp_subnet_name" { type = string }

variable "autoscaler_node_shape" { type = string }
variable "autoscaler_node_minimum_count" { type = number }
variable "autoscaler_node_maximum_count" { type = number }
variable "autoscaler_node_ocpus" { type = number }
variable "autoscaler_node_memory" { type = number }
variable "autoscaler_node_image_id" { type = string }
