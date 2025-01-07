locals {
  is_abi = var.installation_method == "Agent-based" ? true : false
}
