variable "compartment_ocid" {
  type = string
}

variable "oca_repo_name" {
  type = string
}

variable "region" {
  type = string
}

variable "oca_marketplace_listing_id" {
  type = string
}

variable "realm_domain_component" {
  description = "The realm domain component for OCIR URL construction. Leave empty for OC1 (commercial, uses .ocir.io). Set to the realm domain for other realms (e.g. 'oraclegovcloud.com' for OC3)."
  type        = string
  default     = ""
}
