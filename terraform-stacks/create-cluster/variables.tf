variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the current tenancy."
}

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment to create the OpenShift cluster in."
}

variable "cluster_name" {
  type        = string
  description = "<strong><em>(Required)</em></strong> - The name of your OpenShift cluster. It should be the same as what was specified when creating the OpenShift ISO and it should be DNS compatible. The cluster_name value must be 1-54 characters. It can use lowercase alphanumeric characters or hyphen (-), but must start and end with a lowercase letter or a number."
}

variable "installation_method" {
  type        = string
  description = "Assisted Installer (AI) or Agent-based Installer (ABI)"
  default     = "Assisted"
}

variable "create_openshift_instances" {
  type        = bool
  description = "Enable the creation of OpenShift image and instances."
  default     = true
}

variable "openshift_image_source_uri" {
  type        = string
  description = "<strong><em>(Required)</em></strong> - The OCI Object Storage URL for the OpenShift image. Before provisioning resources through this Resource Manager stack, users should upload the OpenShift image to OCI Object Storage, create a Pre-Authenticated Request (PAR) URL, and paste the URL to this block. For more details, review <a href='https://docs.oracle.com/en-us/iaas/Content/Object/Concepts/objectstorageoverview.htm'>Object Storage</a> and <a href='https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/usingpreauthenticatedrequests.htm'>PARs</a>."
  default     = "TODO"
}

variable "tag_namespace_compartment_ocid_resource_tagging" {
  type        = string
  description = "<strong><em>(Required)</em></strong> - <strong>WARNING</strong> - The compartment OCID containing the OpenShift on OCI resource attribution tags. The tag namespace and defined tag for OpenShift on OCI resource attribution should be as follows: {\"openshift-tags\": {\"openshift-resource\": \"openshift-resource-infra\"}}. They can be created using the <a href='https://github.com/oracle-quickstart/oci-openshift/releases/latest/download/create-resource-attribution-tags.zip'>create-resource-attribution-tags</a> Terraform stack. It is required to create the OpenShift on OCI resource attribution tags prior to creating any OpenShift clusters."
}

variable "rendezvous_ip" {
  default     = "10.0.16.20"
  type        = string
  description = "The IP used to bootstrap the cluster using the Agent-based installer. Must be in the private_ocp subnet."
}

variable "is_disconnected_installation" {
  type        = bool
  description = "Indicates whether the cluster will be installed in a disconnected (air-gapped) environment."
  default     = false
}

variable "set_openshift_installer_version" {
  type        = bool
  description = "If you don't want to use the latest version of openshift-installer, specify a specific supported version. For example, 4.19.1."
  default     = false
}

variable "openshift_installer_version" {
  type        = string
  description = "The version of openshift-installer. You can find the published version in <a href='https://mirror.openshift.com/pub/openshift-v4/clients/ocp/'>published version</a>."
  default     = "latest"
}

variable "public_ssh_key" {
  type        = string
  description = "Public SSH key for access to your OpenShift instances and webserver."
  default     = ""
}

variable "redhat_pull_secret" {
  type        = string
  default     = "PULL SECRET"
  description = "The pull secret that you need for authenticate purposes when downloading container images for OpenShift Container Platform components and services, such as Quay.io. See Install OpenShift Container Platform 4 from the Red Hat Hybrid Cloud Console."
}

variable "webserver_private_ip" {
  default     = "10.0.0.200"
  type        = string
  description = "The Private IP of the server where you want to upload the rootfs image. This parameter is required only for disconnected environments. This IP should be included in the bootArtifactsBaseURL value in your agent-config file."
}

variable "webserver_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of webserver instance. The default shape is VM.Standard.E5.Flex. For more details, review OpenShift on OCI <a href='https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes'>supported shapes</a>."
}

variable "webserver_image_source_id" {
  default     = "ocid1.image.oc1.us-sanjose-1.aaaaaaaawgtwtqmz5j2kbvwgk6lm5yx2bnom456skma7q62jb5ltw7zoac4a"
  type        = string
  description = "The source_id of image to use for webserver instance. The default is an OEL 9 instance."
}

variable "webserver_ocpus" {
  type        = number
  description = "The number of OCPUs for the webserver instance."
  default     = 2
}

variable "webserver_memory_in_gbs" {
  type        = number
  description = "The amount of memory for the webserver instance, in GBs."
  default     = 8
}

variable "set_proxy" {
  type        = bool
  description = "If hosts are behind a firewall that requires the use of a proxy, provide additional information about the proxy."
  default     = false
}

variable "http_proxy" {
  type        = string
  description = "The HTTP Proxy URL."
  default     = "Fake http_proxy"
}

variable "https_proxy" {
  type        = string
  description = "The HTTPS Proxy URL."
  default     = "Fake https_proxy"
}

variable "no_proxy" {
  type        = string
  description = "The No Proxy Domains."
  default     = "Fake no_proxy"
}

variable "use_oracle_cloud_agent" {
  description = "Check to enable Oracle Cloud Agent in the cluster."
  type        = bool
  default     = false
}

variable "oracle_cloud_agent_repo_name" {
  description = "Repository that contains the Oracle Cloud Agent container image."
  type        = string
  default     = "openshift-oca"
}

variable "region" {
  type = string
}

variable "control_plane_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of the control_plane nodes. The default shape is VM.Standard.E5.Flex for VM setup and BM.Standard3.64 for BM setup. For more details regarding supported shapes, review OpenShift on OCI <a href='https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes'>supported shapes</a>."
}

variable "control_plane_count" {
  default     = 3
  type        = number
  description = "The number of control_plane nodes in the cluster. The default value is 3."
}

variable "control_plane_ocpu" {
  default     = 4
  type        = number
  description = "The number of OCPUs for each control_plane node. The default value is 4. For BM shapes, this value is ignored."
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
  description = "The size of the boot volume of each control_plane node in GBs. The minimum value is 50 GB and the maximum value is 32,768 GB (32 TB). The default value is 1024 GB."
  validation {
    condition     = var.control_plane_boot_size >= 50 && var.control_plane_boot_size <= 32768
    error_message = "The control_plane_boot_size value must be between 50 and 32768."
  }
}

variable "control_plane_boot_volume_vpus_per_gb" {
  default     = 100
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each control_plane node. The default value is 100."
  validation {
    condition     = var.control_plane_boot_volume_vpus_per_gb >= 10 && var.control_plane_boot_volume_vpus_per_gb <= 120 && var.control_plane_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The control_plane_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}

variable "distribute_cp_instances_across_ads" {
  description = "Enable control-plane instances to be distributed across all Availability Domains (ADs) in a round-robin sequence starting from your selected AD. If false, then all instances will be created in the selected starting AD."
  type        = bool
  default     = true
}

variable "starting_ad_name_cp" {
  description = "Specify the Availability Domain for initial node placement. Additional nodes will be automatically distributed across ADs in a round-robin sequence starting from your selected AD unless distribute_cp_instances_across_ads is false."
  type        = string
  default     = null
}

variable "distribute_cp_instances_across_fds" {
  description = "Enable control-plane instances to be distributed across all Fault Domains (FDs) in a round-robin sequence. If false, then the OCI Compute service will select one for you based on shape availability."
  type        = bool
  default     = true
}

variable "compute_shape" {
  default     = "VM.Standard.E5.Flex"
  type        = string
  description = "Compute shape of the compute nodes. The default shape is VM.Standard.E5.Flex for VM setup and BM.Standard3.64 for BM setup. For more details regarding supported shapes, review OpenShift on OCI <a href='https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes'>supported shapes</a>."
}

variable "compute_count" {
  default     = 3
  type        = number
  description = "The number of compute nodes in the cluster. The default value is 3."
}

variable "compute_ocpu" {
  default     = 6
  type        = number
  description = "The number of OCPUs for each compute node. The default value is 6. For BM shapes, this value is ignored."
  validation {
    condition     = var.compute_ocpu >= 1 && var.compute_ocpu <= 114
    error_message = "The compute_ocpu value must be between 1 and 114."
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

variable "compute_boot_volume_vpus_per_gb" {
  default     = 30
  type        = number
  description = "The number of volume performance units (VPUs) that will be applied to this volume per GB of each compute node. The default value is 30. "
  validation {
    condition     = var.compute_boot_volume_vpus_per_gb >= 10 && var.compute_boot_volume_vpus_per_gb <= 120 && var.compute_boot_volume_vpus_per_gb % 10 == 0
    error_message = "The compute_boot_volume_vpus_per_gb value must be between 10 and 120, and must be a multiple of 10."
  }
}

variable "distribute_compute_instances_across_ads" {
  description = "Whether compute instances should be distributed across ADs in a round-robin sequence starting from your selected AD. If false, then all nodes will be created in the selected starting AD."
  type        = bool
  default     = true
}

variable "starting_ad_name_compute" {
  description = "Name of the AD to start node distribution from"
  type        = string
  default     = null
}

variable "distribute_compute_instances_across_fds" {
  description = "Whether compute instances should be distributed across Fault Domains in a round-robin sequence. If false, then the OCI Compute service will select one for you based on shape availability."
  type        = bool
  default     = true
}

variable "create_public_dns" {
  type        = bool
  description = "Create a public DNS zone with your Base domain specified in Zone DNS. If this is not created, it is advised that you create a private DNS zone unless you are bringing your own DNS solution. To resolve cluster hostnames without DNS, users should add entries to /etc/hosts mapping the cluster hostnames to the IP address of the api_apps Load Balancer. The etc_hosts_entry output can be used for this purpose."
  default     = true
}

variable "enable_public_api_lb" {
  type        = bool
  description = "Create a Load Balancer for the OpenShift API endpoint (`api.<cluster>.<base_domain>`) in the public subnet with a public IP address. This allows users and administrators to access the OpenShift control plane over the internet. If disabled, the API Load Balancer will be created in a private subnet with a private IP, limiting access to within the VCN or through a connected VPN/private network. Public API access is useful for remote cluster management, automation, and CI/CD pipelines. In on-premise environments (e.g., C3/PCA), \"public\" IPs may refer to RFC 1918 addresses that are only routable within your internal network. Consult your network administrator to confirm external access.."
  default     = false
}

variable "enable_public_apps_lb" {
  type        = bool
  description = "Create a Load Balancer for OpenShift applications (`*.apps.<cluster>.<base_domain>`) in the public subnet with a public IP address. This allows external users to access workloads and services deployed in the cluster. If disabled, the Apps Load Balancer will be created in a private subnet with a private IP, making application routes accessible only within the VCN or over a VPN/private network. Public access is useful for exposing applications to the internet, customer-facing services, or multi-tenant workloads. In on-premise setups (e.g., C3/PCA), \"public\" IPs may be RFC 1918 addresses that are still treated as public within the internal network. Coordinate with your network team for proper exposure."
  default     = true
}

variable "create_private_dns" {
  type        = bool
  description = "Create a private DNS zone with your Base domain specified in Zone DNS. It will contain the same records as a public DNS zone and will facilitate the cluster's hostname resolution within the VCN. If using an unregistered domain name as the Base domain for your cluster, you should create a private DNS zone if possible, or you will have to take other measures to help the instances resolve the cluster's hostname. For more details, review <a href='https://docs.oracle.com/en-us/iaas/Content/DNS/Tasks/privatedns.htm'>Oracle Private DNS</a>."
  default     = false
}

variable "zone_dns" {
  type        = string
  description = "<strong><em>(Required)</em></strong> - The name of the cluster's DNS zone. This name must be the same as what was specified during OpenShift ISO creation. The zone_dns value must be a valid hostname."
}

variable "use_existing_network" {
  description = "Use existing networking infrastructure."
  type        = bool
  default     = false
}

variable "networking_compartment_ocid" {
  type        = string
  description = "Select the compartment where the existing networking resources are located. This may be different or same from the main compartment where OpenShift resources will be created."
  default     = ""
}

variable "existing_vcn_id" {
  description = "The OCID of the existing VCN to use when use_existing_network is true."
  type        = string
  default     = ""
}

variable "existing_private_ocp_subnet_id" {
  description = "The OCID of the existing private subnet for OCP to use when use_existing_network is true."
  type        = string
  default     = ""
}

variable "existing_private_bare_metal_subnet_id" {
  description = "The OCID of the existing private subnet for Bare Metal to use when use_existing_network is true. This should be different from the private_ocp subnet or else you may experience issues."
  type        = string
  default     = ""
}

variable "existing_public_subnet_id" {
  description = "The OCID of the existing public subnet to use when use_existing_network is true."
  type        = string
  default     = ""
}

variable "object_storage_namespace" {
  type        = string
  description = "The OCI Object Storage namespace for the tenancy. See https://docs.oracle.com/en-us/iaas/Content/Object/Tasks/understandingnamespaces.htm"
  default     = ""
}

variable "object_storage_bucket" {
  type        = string
  description = "Name of the OCI Object Storage bucket where the OpenShift installation files will be stored."
  default     = ""
}

# variable "openshift_iso_object_name" {
#   type        = string
#   description = "Name for the ISO object to be uploaded to OCI Object Storage (e.g., my-cluster-agent.iso)."
#   default     = ""
# }
variable "vcn_dns_label" {
  default     = "openshiftvcn"
  type        = string
  description = "A DNS label for the VCN, used in conjunction with the VNIC's hostname and subnet's DNS label to form a fully qualified domain name (FQDN) for each VNIC within this subnet (for example, bminstance1.subnet123.vcn1.oraclevcn.com). Must be an alphanumeric string that begins with a letter."
  validation {
    condition     = can(regex("^([a-z0-9]{1,15})$", var.vcn_dns_label))
    error_message = "The vcn_dns_label value must be 1-15 characters. It can use lowercase alphanumeric characters, but must start with a lowercase letter."
  }
}

variable "vcn_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "The IPv4 CIDR block for the VCN of your OpenShift Cluster. The default value is `10.0.0.0/16`. "
}

variable "public_cidr" {
  default     = "10.0.0.0/20"
  type        = string
  description = "The IPv4 CIDR block for the public subnet of your OpenShift Cluster. The default value is `10.0.0.0/20`. "
}

variable "private_cidr_ocp" {
  default     = "10.0.16.0/20"
  type        = string
  description = "The IPv4 CIDR block for the private subnet for OCP of your OpenShift Cluster. The default value is `10.0.16.0/20`. "
}

variable "private_cidr_bare_metal" {
  default     = "10.0.32.0/20"
  type        = string
  description = "The IPv4 CIDR block for the private subnet for Bare Metal of your OpenShift Cluster. The default value is `10.0.32.0/20`."
}

variable "load_balancer_shape_details_maximum_bandwidth_in_mbps" {
  default     = 500
  type        = number
  description = "Bandwidth in Mbps that determines the maximum bandwidth (ingress plus egress) that the load balancer can achieve. The values must be between minimumBandwidthInMbps and 8000."
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

variable "oci_driver_version" {
  type        = string
  description = "The OCI CCM and CSI driver version. Select what version of the OCI CCM and CSI driver manifests to include in the `dynamic_custom_manifest` output. See available versions in <a href='https://github.com/oracle-quickstart/oci-openshift/tree/main/custom_manifests/oci-ccm-csi-drivers'>oci-openshift/custom_manifests/oci-ccm-csi-drivers</a>"
  default     = "v1.32.0"
}

variable "use_existing_tags" {
  type        = bool
  description = "Indicates whether to reuse existing instance role tag namespace and defined tags when tagging OCI resources. By default, a new set of instance role tagging resources are created and destroyed with the rest of the cluster resources. Optionally, you can create instance role tagging resources separately that can be reused with the Terraform from <a href='https://github.com/oracle-quickstart/oci-openshift/tree/main/terraform-stacks/create-instance-role-tags'>oci-openshift/terraform-stacks/create-instance-role-tags</a>. Existing instance role tagging resources will not be destroyed when the cluster is."
  default     = false
}

variable "tag_namespace_name" {
  type        = string
  description = "The name of the instance role tag namespace to reuse. Defaults to `openshift-{cluster_name}` if unspecified."
  default     = ""
  validation {
    condition     = var.tag_namespace_name == "" || can(regex("^openshift-", var.tag_namespace_name))
    error_message = "The tag namespace name must start with 'openshift-'."
  }
}

variable "tag_namespace_compartment_ocid" {
  type        = string
  description = "The OCI of the compartment containing existing instance role tag namespace. Defaults to current compartment."
  default     = ""
}
