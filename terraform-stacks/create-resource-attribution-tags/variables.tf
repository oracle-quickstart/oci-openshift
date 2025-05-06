variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}

variable "tag_namespace_compartment_ocid_resource_tagging" {
  type        = string
  description = "The compartment where the tag namespace for OpenShift Resource Attribution tags should be created."
}
