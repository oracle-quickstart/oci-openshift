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
  validation {
    condition     = var.tag_namespace_name == "" || can(regex("^openshift-", var.tag_namespace_name))
    error_message = "The tag namespace name must start with 'openshift-'."
  }
}

variable "wait_for_new_tag_consistency_wait_time" {
  type = string
}
