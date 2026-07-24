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
variable "autoscaler_node_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of the autoscaler nodes. The default shape is VM.Standard.E5.Flex for VM setup and BM.Standard3.64 for BM setup. For more details regarding supported shapes, review OpenShift on OCI <a href='https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes'>supported shapes</a>."
}

variable "autoscaler_node_image_source_uri" {
  type        = string
  description = "<strong><em>(Required)</em></strong> - The OCI Object Storage URL for the Autoscaler node image. Before provisioning resources through this Resource Manager stack, users should upload the OpenShift image to OCI Object Storage, create a Pre-Authenticated Request (PAR) URL, and paste the URL to this block."
  default     = ""
}

# Autoscaler config values
variable "autoscaler_node_minimum_count" {
  default     = 0
  type        = number
  description = "The minimum number of autoscaled nodes in the cluster. The default value is 0."

  validation {
    condition     = var.autoscaler_node_minimum_count >= 0
    error_message = "The autoscaler_node_minimum_count value must be greater than or equal to 0."
  }
}

variable "autoscaler_node_maximum_count" {
  default     = 5
  type        = number
  description = "The maximum number of autoscaled nodes in the cluster. The default value is 5."
}

variable "autoscaler_pool_identifier" {
  default     = ""
  type        = string
  description = "Optional lowercase identifier appended to the CAPI cluster name when naming autoscaler node pool resources. Use up to 5 lowercase letters, numbers, or hyphens, such as bm01, vm01, or gpu01. The value must start and end with a lowercase letter or number."

  validation {
    condition     = var.autoscaler_pool_identifier == "" || can(regex("^[a-z0-9]([-a-z0-9]{0,3}[a-z0-9])?$", var.autoscaler_pool_identifier))
    error_message = "The autoscaler_pool_identifier value must be empty or up to 5 characters containing lowercase letters, numbers, and hyphens, and must start and end with a lowercase letter or number."
  }
}

variable "autoscaler_node_ocpus" {
  default     = 4
  type        = number
  description = "The number of OCPUs for each autoscaled node. The default value is 4. For BM shapes, this value is ignored and determined by the shape selected."

  validation {
    condition     = var.autoscaler_node_ocpus >= 1 && var.autoscaler_node_ocpus <= 144
    error_message = "The autoscaler_node_ocpus value must be between 1 and 144."
  }
}

variable "autoscaler_node_memory" {
  default     = 24
  type        = number
  description = "The amount of memory available for the shape of each autoscaled node, in gigabytes. The default value is 24. For BM shapes, this value is ignored and determined by the shape selected."

  validation {
    condition     = var.autoscaler_node_memory >= 1 && var.autoscaler_node_memory <= 1760
    error_message = "The autoscaler_node_memory value must be between the value of 1 and 1760."
  }
}
variable "cluster_network_cidr_block" {
  default     = "10.128.0.0/14"
  type        = string
  description = "The CIDR block for the OpenShift cluster network."
}
variable "service_network_cidr_block" {
  default     = "172.30.0.0/16"
  type        = string
  description = "The CIDR block for the OpenShift service network."
}
variable "autoscaler_defined_tags_namespace" {
  type    = string
  default = ""

  validation {
    condition     = var.autoscaler_defined_tags_namespace == "" || can(regex("^openshift-", var.autoscaler_defined_tags_namespace))
    error_message = "The autoscaler_defined_tags_namespace value must start with 'openshift-'."
  }
}

variable "region" { type = string }
