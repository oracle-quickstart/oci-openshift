variable "create_openshift_instances" {
  type = bool
}

variable "compartment_ocid" {
  type = string
}

variable "is_control_plane_iscsi_type" {
  type = bool
}

variable "is_compute_iscsi_type" {
  type = bool
}

variable "image_name" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}

variable "openshift_image_source_uri" {
  type = string
}

variable "control_plane_shape" {
  type = string
}

variable "compute_shape" {
  type = string
}
