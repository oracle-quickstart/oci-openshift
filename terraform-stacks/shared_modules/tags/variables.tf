variable "use_existing_tags" {
  type = bool
}

variable "compartment_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "tag_namespace_compartment_ocid" {
  type = string
}

variable "tag_namespace_name" {
  type = string
}

variable "openshift_tag_openshift_resource_value" {
  type = string
}

variable "wait_for_new_tag_consistency_wait_time" {
  type = string
}
