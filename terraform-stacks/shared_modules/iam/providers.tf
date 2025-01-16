terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.1"
    }
  }
}
