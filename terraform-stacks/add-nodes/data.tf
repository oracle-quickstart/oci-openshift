data "oci_identity_tag_namespaces" "openshift_tag_namespace" {
  compartment_id          = var.tenancy_ocid
  include_subcompartments = true
  state                   = "ACTIVE"
  filter {
    name   = "name"
    values = [local.cluster_instance_role_tag_namespace]
    regex  = true
  }
}

data "oci_load_balancer_load_balancers" "openshift_api_apps_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-openshift_api_apps_lb"
}

data "oci_load_balancer_load_balancers" "openshift_api_int_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-openshift_api_int_lb"
}

data "oci_load_balancer_backends" "openshift_api_apps_api_backend" {
  backendset_name  = "openshift_cluster_api_backend"
  load_balancer_id = data.oci_load_balancer_load_balancers.openshift_api_apps_lb.load_balancers[0].id
}

data "oci_load_balancer_backends" "openshift_api_apps_ingress_http" {
  backendset_name  = "openshift_cluster_ingress_http"
  load_balancer_id = data.oci_load_balancer_load_balancers.openshift_api_apps_lb.load_balancers[0].id
}

data "oci_core_vcns" "cluster_vcn" {
  compartment_id = var.compartment_ocid
  display_name   = var.cluster_name
}

data "oci_core_subnets" "private_opc" {
  compartment_id = var.compartment_ocid
  display_name   = "private_opc"
  vcn_id         = data.oci_core_vcns.cluster_vcn.virtual_networks[0].id
}

data "oci_core_subnets" "private_bare_metal" {
  compartment_id = var.compartment_ocid
  display_name   = "private_bare_metal"
  vcn_id         = data.oci_core_vcns.cluster_vcn.virtual_networks[0].id
}

data "oci_core_network_security_groups" "cluster_controlplane_nsg" {
  compartment_id = var.compartment_ocid
  display_name   = "cluster-controlplane-nsg"
  vcn_id         = data.oci_core_vcns.cluster_vcn.virtual_networks[0].id
}

data "oci_core_network_security_groups" "cluster_compute_nsg" {
  compartment_id = var.compartment_ocid
  display_name   = "cluster-compute-nsg"
  vcn_id         = data.oci_core_vcns.cluster_vcn.virtual_networks[0].id
}
