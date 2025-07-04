variable "zone_dns" {
  type        = string
  description = "The name of cluster's DNS zone. This name must be the same as what was specified during OpenShift ISO creation. The zone_dns value must be a valid hostname."
}

variable "control_plane_count" {
  default     = 3
  type        = number
  description = "The number of control_plane nodes in the cluster. The default value is 3. "
}

variable "control_plane_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of the control_plane nodes. The default shape is VM.Standard.E5.Flex for VM setup and BM.Standard3.64 for BM setup. For more detail regarding supported shapes, please visit https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes"
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
  default     = 3
  type        = number
  description = "The number of compute nodes in the cluster. The default value is 3. "
}

variable "compute_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of the compute nodes. The default shape is BM.Standard3.64. For more detail regarding supported shapes, please visit https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes"
}

variable "compute_ocpu" {
  default     = 6
  type        = number
  description = "The number of OCPUs available for the shape of each compute node. The default value is 6. "

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

variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  default     = 500
  type        = number
  description = "Bandwidth in Mbps that determines the maximum bandwidth (ingress plus egress) that the load balancer can achieve. The values must be between minimumBandwidthInMbps and 8000"

  validation {
    condition     = var.load_balancer_shape_details_maximum_bandwidth_in_mbps >= 10 && var.load_balancer_shape_details_maximum_bandwidth_in_mbps <= 8000
    error_message = "The load_balancer_shape_details_maximum_bandwidth_in_mbps value must be between load_balancer_shape_details_minimum_bandwidth_in_mbps and 8000."
  }
}

variable "load_balancer_shape_details_minimum_bandwidth_in_mbps" {
  default     = 10
  type        = number
  description = " Bandwidth in Mbps that determines the total pre-provisioned bandwidth (ingress plus egress). The values must be between 10 and the maximumBandwidthInMbps"

  validation {
    condition     = var.load_balancer_shape_details_minimum_bandwidth_in_mbps >= 10 && var.load_balancer_shape_details_minimum_bandwidth_in_mbps <= 8000
    error_message = "The load_balancer_shape_details_maximum_bandwidth_in_mbps value must be between 10 and load_balancer_shape_details_maximum_bandwidth_in_mbps."
  }
}

variable "tenancy_ocid" {
  type        = string
  description = "The ocid of the current tenancy."
}

## Openshift infrastructure compartment
variable "compartment_ocid" {
  type        = string
  description = "The ocid of the compartment where you wish to create the OpenShift cluster."
}

## Openshift cluster name
variable "cluster_name" {
  type        = string
  description = "The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible. The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
}

variable "vcn_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "The IPv4 CIDR blocks for the VCN of your OpenShift Cluster. The default value is 10.0.0.0/16. "
}

variable "vcn_dns_label" {
  default     = "openshiftvcn"
  type        = string
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet (for example, bminstance1.subnet123.vcn1.oraclevcn.com). Must be an alphanumeric string that begins with a letter"
  validation {
    condition     = can(regex("^([a-z0-9]{1,15})$", var.vcn_dns_label))
    error_message = "The vcn_dns_label value must be 1-15 characters. It can use lowercase alphanumeric characters, but must start with a lowercase letter."
  }
}

variable "private_cidr_ocp" {
  default     = "10.0.16.0/20"
  type        = string
  description = "The IPv4 CIDR blocks for the private subnet of your OpenShift Cluster. The default value is 10.0.16.0/20. "
}

variable "private_cidr_bare_metal" {
  default     = "10.0.32.0/20"
  type        = string
  description = "The IPv4 CIDR blocks for the private subnet of your OpenShift Cluster. The default value is 10.0.32.0/20."
}

variable "public_cidr" {
  default     = "10.0.0.0/20"
  type        = string
  description = "The IPv4 CIDR blocks for the public subnet of your OpenShift Cluster. The default value is 10.0.0.0/20. "
}

variable "openshift_image_source_uri" {
  type        = string
  description = "The OCI Object Storage URL for the OpenShift image. Before provisioning resources through this Resource Manager stack, users should upload the OpenShift image to OCI Object Storage, create a pre-authenticated requests (PAR) uri, and paste the uri to this block. For more detail regarding Object storage and PAR, please visit https://docs.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm and https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingpreauthenticatedrequests.htm ."
  default     = "TODO"
}

variable "oci_driver_version" {
  type    = string
  default = "v1.30.0"
}

variable "create_public_dns" {
  type        = bool
  description = "If enabled, a public DNS zone will be created."
  default     = true
}

variable "enable_public_api_lb" {
  type        = bool
  description = "If enabled, the api load balancer will be created with a public IP. Otherwise, they will be created in the private_ocp subnet and be accessible only within the VCN."
  default     = false
}

variable "enable_public_apps_lb" {
  type        = bool
  description = "If enabled, the apps load balancer will be created with a public IP. Otherwise, they will be created in the private_ocp subnet and be accessible only within the VCN."
  default     = true
}

variable "create_private_dns" {
  type        = bool
  description = "If enabled, a private DNS zone will be created."
  default     = false
}

variable "create_openshift_instances" {
  type    = bool
  default = true
}

variable "installation_method" {
  type    = string
  default = "Assisted"
}

variable "rendezvous_ip" {
  default     = "10.0.16.20"
  type        = string
  description = "RendezvousIP from ABI"
}

variable "use_existing_tags" {
  type        = bool
  description = "Indicates whether to reuse existing tag namespace and defined tags when tagging OCI resources. Tag namespace and defined tags are preserved when the stack is destroyed if reuse_tags is set to true. WARNING - Stack creation will fail if specifed tag namespace and defined tags do not exist as specified. Create stack with reuse_tags set to false to create tagging resources that are destroyed when the cluster is, or use the terraform from oci-openshift/tagging-resources to create tagging resources seperately. It's recommended you do not change this flag after cluster creation to preserve terraform state consistency."
  default     = false
}

variable "tag_namespace_name" {
  type        = string
  description = "Name of tag namespace to create or use for OCI resources tags. Defaults to \"openshift-{cluster_name}\""
  default     = ""
  validation {
    condition     = var.tag_namespace_name == "" || can(regex("^openshift-", var.tag_namespace_name))
    error_message = "The tag namespace name must start with 'openshift-'."
  }
}

variable "tag_namespace_compartment_ocid" {
  type        = string
  description = "Compartment containing tag namespace. Defaults to current compartment."
  default     = ""
}

variable "tag_namespace_compartment_ocid_resource_tagging" {
  type        = string
  description = "The compartment where the tag namespace for OpenShift Resource Attribution tags should be created."
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

variable "distribute_cp_instances_across_fds" {
  description = "Whether control-plane instances should be distributed across Fault Domains in a round-robin sequence. If false, then the OCI Compute service will select one for you based on shape availability."
  type        = bool
  default     = true
}

variable "distribute_compute_instances_across_fds" {
  description = "Whether compute instances should be distributed across Fault Domains in a round-robin sequence. If false, then the OCI Compute service will select one for you based on shape availability."
  type        = bool
  default     = true
}
