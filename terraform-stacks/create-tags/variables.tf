variable "tag_namespace_compartment_ocid" {
  type        = string
  description = "Compartment to create tag namespace in. Defaults to current compartment."
}

variable "tag_namespace_name" {
  type        = string
  description = "Name of tag namespace to create for tagging OpenShift OCI resources. WARNING - Tag namespace name must be unique accross the tenancy."
}

variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}
