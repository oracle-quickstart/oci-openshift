variable "tag_namespace_compartment_ocid_resource_tagging" {
  type = string
}

variable "openshift_attribution_tag_namespace" {
  type    = string
  default = "openshift-tags"
}

variable "openshift_attribution_tag_key" {
  type    = string
  default = "openshift-resource"
}

variable "openshift_attribution_tag_value" {
  type    = string
  default = "openshift-resource-infra"
}
