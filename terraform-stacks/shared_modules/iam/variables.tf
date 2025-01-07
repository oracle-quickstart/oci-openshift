variable "compartment_ocid" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "op_openshift_tag_namespace" {
  type = string
}

variable "op_openshift_tag_instance_role" {
  type = string
}

variable "openshift_tag_openshift_resource_value" {
  type = string
}

variable "op_openshift_tag_openshift_resource" {
  type = string
}

variable "defined_tags" {
  type = map(string)
}
