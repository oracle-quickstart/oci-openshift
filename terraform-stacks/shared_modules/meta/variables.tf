variable "compartment_ocid" {
  type = string
}

variable "control_plane_count" {
  type = number
}

variable "compute_count" {
  type = number
}

variable "current_cp_count" {
  type    = number
  default = 0
}

variable "current_compute_count" {
  type    = number
  default = 0
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

variable "starting_fd_name_cp" {
  description = "Name of the FD to start node distribution from"
  type        = string
  default     = null
}

variable "starting_fd_name_compute" {
  description = "Name of the FD to start node distribution from"
  type        = string
  default     = null
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
