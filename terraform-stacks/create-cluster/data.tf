data "oci_core_subnet" "autoscaler_ocp_subnet" {
  subnet_id = module.network.op_subnet_private_ocp
}

data "oci_core_subnet" "autoscaler_bare_metal_subnet" {
  count = local.is_autoscaler_bm_shape ? 1 : 0

  subnet_id = module.network.op_subnet_private_bare_metal
}
