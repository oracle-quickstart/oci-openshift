variable "tag_namespace_compartment_ocid_resource_tagging" {
  type        = string
  description = "The compartment where the tag namespace for OpenShift Resource Attribution tagging should be created."
}


variable "openshift_attribution_tag_namespace" {
  type    = string
  default = "openshift-tags"
}

variable "openshift_attribution_tag_key" {
  type    = string
  default = "openshift-resource"
}
