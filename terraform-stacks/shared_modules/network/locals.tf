data "oci_core_services" "oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

locals {
  anywhere      = "0.0.0.0/0"
  all_protocols = "all"
}
