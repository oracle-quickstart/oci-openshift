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

data "oci_load_balancer_load_balancers" "openshift_api_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-openshift_api_lb"
}

data "oci_load_balancer_load_balancers" "openshift_apps_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-openshift_apps_lb"
}

data "oci_load_balancer_load_balancers" "openshift_api_int_lb" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.cluster_name}-openshift_api_int_lb"
}

data "oci_load_balancer_backends" "openshift_api_backend" {
  backendset_name  = "openshift_cluster_api_backend"
  load_balancer_id = data.oci_load_balancer_load_balancers.openshift_api_lb.load_balancers[0].id
}

data "oci_load_balancer_backends" "openshift_apps_ingress_http" {
  backendset_name  = "openshift_cluster_ingress_http"
  load_balancer_id = data.oci_load_balancer_load_balancers.openshift_apps_lb.load_balancers[0].id
}
