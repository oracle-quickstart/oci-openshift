variable "tenancy_ocid" { type = string }
variable "compartment_ocid" { type = string }
variable "cluster_name" { type = string }

# Existing network inputs (since this stack should not create infra)
variable "existing_vcn_id" { type = string }
variable "existing_private_ocp_subnet_id" { type = string }
variable "bare_metal_subnet_id" {
  type    = string
  default = ""
}

variable "networking_compartment_ocid" {
  type    = string
  default = ""
}

variable "subnet_compartment_ocid" {
  type    = string
  default = ""
}

# variable "api_lb_id_override" {
#   type    = string
#   default = ""
# }

# variable "lb_nsg_id_override" {
#   type    = string
#   default = ""
# }

# # Tagging lookup

# Image inputs for autoscaling image generation (reuses image module behavior)
variable "autoscaler_node_shape" { type = string }
variable "autoscaler_node_image_source_uri" { type = string }

# Autoscaler config values
variable "autoscaler_node_minimum_count" {
  type = number

  validation {
    condition     = var.autoscaler_node_minimum_count >= 0
    error_message = "The autoscaler_node_minimum_count value must be greater than or equal to 0."
  }
}

variable "autoscaler_node_maximum_count" { type = number }

variable "autoscaler_node_ocpus" {
  type = number

  validation {
    condition     = var.autoscaler_node_ocpus >= 1 && var.autoscaler_node_ocpus <= 144
    error_message = "The autoscaler_node_ocpus value must be between 1 and 144."
  }
}

variable "autoscaler_node_memory" {
  type = number

  validation {
    condition     = var.autoscaler_node_memory >= 1 && var.autoscaler_node_memory <= 1760
    error_message = "The autoscaler_node_memory value must be between 1 and 1760."
  }
}
variable "cluster_network_cidr_block" {
  type    = string
  default = "10.128.0.0/14"
}
variable "service_network_cidr_block" {
  type    = string
  default = "172.30.0.0/16"
}
variable "autoscaler_defined_tags_namespace" {
  type    = string
  default = ""
}

variable "region" { type = string }
