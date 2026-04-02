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
