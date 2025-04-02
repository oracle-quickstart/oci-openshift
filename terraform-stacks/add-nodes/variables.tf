variable "control_plane_count" {
  default     = 0
  type        = number
  description = "The number of control_plane nodes in the cluster. The default value is 3. "
}

variable "control_plane_shape" {
  default     = "VM.Standard.E4.Flex"
  type        = string
  description = "Compute shape of the control_plane nodes. The default shape is VM.Standard.E4.Flex for VM setup and BM.Standard3.64 for BM setup. For more detail regarding supported shapes, please visit https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes"
}

variable "control_plane_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs available for the shape of each control_plane node. The default value is 4 for VM and 64 for BM."

  validation {
    condition     = var.control_plane_ocpu >= 1 && var.control_plane_ocpu <= 114
    error_message = "The control_plane_ocpu value must be between 1 and 114."
  }
}

variable "control_plane_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each control_plane node, in gigabytes. The default value is 16 for VM and 1024 for BM."

  validation {
    condition     = var.control_plane_memory >= 1 && var.control_plane_memory <= 1760
    error_message = "The control_plane_memory value must be between the value of control_plane_ocpu and 1760."
  }
}

variable "control_plane_boot_size" {
  default     = 1024
  type        = number
  description = "The size of the boot volume of each control_plane node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 1024 GB. "

  validation {
    condition     = var.control_plane_boot_size >= 50 && var.control_plane_boot_size <= 32768
    error_message = "The control_plane_boot_size value must be between 50 and 32768."
  }
}

variable "control_plane_boot_volume_vpus_per_gb" {
  default     = 100
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each control_plane node. The default value is 90. "

  validation {
    condition     = var.control_plane_boot_volume_vpus_per_gb >= 10 && var.control_plane_boot_volume_vpus_per_gb <= 120 && var.control_plane_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The control_plane_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}

variable "compute_count" {
  default     = 1
  type        = number
  description = "The number of compute nodes in the cluster. The default value is 3. "
}

variable "compute_shape" {
  default     = "VM.Standard.E4.Flex"
  type        = string
  description = "Compute shape of the compute nodes. The default shape is BM.Standard3.64. For more detail regarding supported shapes, please visit https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes"
}

variable "compute_ocpu" {
  default     = 6
  type        = number
  description = "The number of OCPUs available for the shape of each compute node. The default value is 4. "

  validation {
    condition     = var.compute_ocpu >= 1 && var.compute_ocpu <= 114
    error_message = "The compute_ocpu value must be between 1 and 114."
  }
}

variable "compute_boot_volume_vpus_per_gb" {
  default     = 30
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each compute node. The default value is 30. "

  validation {
    condition     = var.compute_boot_volume_vpus_per_gb >= 10 && var.compute_boot_volume_vpus_per_gb <= 120 && var.compute_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The compute_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}

variable "compute_memory" {
  default     = 16
  type        = number
  description = "The amount of memory available for the shape of each compute node, in gigabytes. The default value is 16."

  validation {
    condition     = var.compute_memory >= 1 && var.compute_memory <= 1760
    error_message = "The compute_memory value must be between the value of compute_ocpu and 1760."
  }
}

variable "compute_boot_size" {
  default     = 100
  type        = number
  description = "The size of the boot volume of each compute node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 100 GB."

  validation {
    condition     = var.compute_boot_size >= 50 && var.compute_boot_size <= 32768
    error_message = "The compute_boot_size value must be between 50 and 32768."
  }
}

variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}

variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment where you wish to create the OpenShift cluster."
}

variable "cluster_name" {
  type        = string
  description = "The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible. The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
}

variable "openshift_image_source_uri" {
  type        = string
  description = "The OCI Object Storage URL for the OpenShift image. Before provisioning resources through this Resource Manager stack, users should upload the OpenShift image to OCI Object Storage, create a pre-authenticated requests (PAR) uri, and paste the uri to this block. For more detail regarding Object storage and PAR, please visit https://docs.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm and https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingpreauthenticatedrequests.htm ."
}

variable "starting_ad_name_cp" {
  description = "Name of the AD to start node distribution from"
  type        = string
  default     = null
}

variable "starting_ad_name_compute" {
  description = "Name of the AD to start node distribution from"
  type        = string
  default     = null
}

variable "tag_namespace_compartment_ocid_resource_tagging" {
  type        = string
  description = "The compartment where the tag namespace for OpenShift Resource Attribution tagging should be created."
}

variable "distribute_cp_instances_across_ads" {
  description = "Whether control-plane instances should be distributed across ADs in a round-robin sequence starting from your selected AD. If false, then all nodes will be created in the selected starting AD."
  type        = bool
  default     = true
}

variable "distribute_compute_instances_across_ads" {
  description = "Whether compute instances should be distributed across ADs in a round-robin sequence starting from your selected AD. If false, then all nodes will be created in the selected starting AD."
  type        = bool
  default     = true
}

variable "cluster_instance_role_tag_namespace" {
  description = "To assign roles like control_plane or compute to instances, a Tag Namespace is required. If you're using the default format openshift-'$cluster_name', you can skip specifying the Tag Namespace—it's automatically detected using the cluster name. If your setup uses a custom format, be sure to provide the correct Tag Namespace explicitly."
  type        = string
  default     = ""
}
