variable "compartment_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "rootfs_file_path" {
  type    = string
  default = ""
}

variable "region" {
  type = string
}

variable "realm_domain" {
  type    = string
  default = "oraclecloud.com"
}

variable "par_expiry_hours" {
  type    = number
  default = 168
}

variable "defined_tags" {
  type = map(string)
}
