variable "compartment_ocid" {
  type = string
}

variable "oci_driver_version" {
  type = string

  validation {
    condition     = var.oci_driver_version == "v1.34.0"
    error_message = "The create-cluster stack only supports oci_driver_version = v1.34.0."
  }
}

variable "op_vcn_openshift_vcn" {
  type = string
}

variable "op_apps_subnet" {
  type = string
}

variable "op_apps_security_list" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "zone_dns" {
  type = string
}

variable "rendezvous_ip" {
  type = string
}

variable "webserver_private_ip" {
  type = string
}

variable "vcn_cidr" {
  type = string
}

variable "compute_count" {
  type = number
}

variable "control_plane_count" {
  type = number
}

variable "public_ssh_key" {
  type = string
}

variable "redhat_pull_secret" {
  type = string
}

variable "http_proxy" {
  type    = string
  default = "fake http_proxy"
}

variable "https_proxy" {
  type    = string
  default = "fake https_proxy"
}

variable "no_proxy" {
  type    = string
  default = "fake no_proxy"
}

variable "is_disconnected_installation" {
  type    = bool
  default = false
}

variable "set_proxy" {
  type    = bool
  default = false
}

variable "use_oracle_cloud_agent" {
  type    = bool
  default = false
}

variable "oca_image_pull_link" {
  type    = string
  default = ""
}

variable "region_metadata" {
  type = string
}

variable "region" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "op_network_security_group_cluster_lb_nsg" {
  type = string
}

variable "op_subnet_private_ocp" {
  type = string
}

variable "op_lb_openshift_api_lb" {
  type = string
}

variable "op_lb_openshift_api_lb_ip_addr" {
  type = string
}

variable "use_autoscaling_operator" {
  type = bool
}

variable "autoscalar_node_shape" {
  type = string
}

variable "autoscalar_node_minimum_count" {
  type = number
}

variable "autoscalar_node_maximum_count" {
  type = number
}

variable "autoscalar_node_ocpus" {
  type = number
}

variable "autoscalar_node_memory" {
  type = number
}

variable "autoscaler_defined_tags_namespace" {
  type = string
}

variable "bare_metal_subnet_id" {
  type = string
}

variable "bare_metal_subnet_name" {
  type = string
}

variable "ocp_subnet_name" {
  type = string
}

variable "cluster_network_cidr_block" {
  type    = string
  default = "10.128.0.0/14"
}

variable "service_network_cidr_block" {
  type    = string
  default = "172.30.0.0/16"
}

variable "capi_version" {
  type    = string
  default = "v1.12.3"
}

variable "capoci_version" {
  type    = string
  default = "v0.24.0"
}

variable "autoscalar_node_image_id" {
  type = string
}
