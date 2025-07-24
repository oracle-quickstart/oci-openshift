variable "is_disconnected_installation" {
  type    = bool
  default = false
}

variable "openshift_installer_version" {
  type        = string
  description = "The version of openshift-installer."
  default     = "latest"
}

variable "webserver_availability_domain" {
  type        = string
  description = "availability domain of webserver instance"
}

variable "webserver_compartment_ocid" {
  type        = string
  description = "compartment id of webserver instance"
}

variable "webserver_shape" {
  type        = string
  description = "shape of webserver instance"
  default     = "VM.Standard.E5.Flex"
}

variable "webserver_display_name" {
  type        = string
  description = "display name of webserver instance"
  default     = "webserver"
}

variable "webserver_private_ip" {
  type        = string
  description = "static private IP for webserver"
}

variable "webserver_assign_public_ip" {
  type        = bool
  description = "Boolean to assign a public IP for webserver"
}

variable "webserver_subnet_id" {
  type        = string
  description = "subnet id of webserver instance"
}

variable "webserver_memory_in_gbs" {
  type        = number
  description = "Memory size of webserver instance"
  default     = 8
}

variable "webserver_ocpus" {
  type        = number
  description = "Number of ocpus for webserver instance"
  default     = 2
}

variable "webserver_image_source_id" {
  type        = string
  description = "source_id of image to use for webserver instance, default is an OEL 9 instance"
  default     = "ocid1.image.oc1.us-sanjose-1.aaaaaaaawgtwtqmz5j2kbvwgk6lm5yx2bnom456skma7q62jb5ltw7zoac4a"
}

variable "webserver_source_type" {
  type        = string
  description = "image source type for webserver instance"
  default     = "image"
}

variable "public_ssh_key" {
  type = string
}

variable "set_proxy" {
  type    = bool
  default = false
}

variable "http_proxy" {
  type    = string
  default = "fake http_proxy"
}

variable "https_proxy" {
  type    = string
  default = "fake https_proxy"
}

variable "no_proxy" {
  type    = string
  default = "fake no_proxy"
}

variable "object_storage_namespace" {
  type        = string
  description = "OCI Object Storage namespace for the tenancy (required for uploading ISO and creating PAR)."
}

variable "object_storage_bucket" {
  type        = string
  description = "Name of the OCI Object Storage bucket to upload the OpenShift agent ISO image."
}

variable "cluster_name" {
  type        = string
  description = "Name of the OpenShift cluster."
}

variable "openshift_tag_namespace" {
  type = string
}

variable "openshift_tag_instance_role" {
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

variable "openshift_tag_openshift_resource_value" {
  type    = string
  default = "openshift-resource-infra"
}

variable "agent_config" {
  type = string
}

variable "install_config" {
  type = string
}

variable "dynamic_custom_manifest" {
  type = string
}
