variable "tag_namespace_compartment_ocid" {
  type        = string
  description = "Compartment to create tag namespace in. Defaults to current compartment."
}

variable "tag_namespace_name" {
  type        = string
  description = "Name of tag namespace to create for OpenShift OCI resources tags. WARNING - Tag namespace name must be unique accross the tenancy and must begin with openshift-."
  validation {
    condition     = var.tag_namespace_name == "" || can(regex("^openshift-", var.tag_namespace_name))
    error_message = "The tag namespace name must start with 'openshift-'."
  }
}

variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}
