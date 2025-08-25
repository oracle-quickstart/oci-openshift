resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_set_external" {
  health_checker {
    protocol          = "HTTP"
    port              = 6080
    return_code       = 200
    url_path          = "/readyz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_api_backend"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_external" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_external.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_http_backend_set" {
  health_checker {
    protocol          = "TCP"
    port              = 80
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_ingress_http"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_apps_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_http" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_http_backend_set.name
  name                     = "openshift_cluster_ingress_http"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_apps_lb.id
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_ingress_https_backend_set" {
  health_checker {
    protocol          = "TCP"
    port              = 443
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_ingress_https"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_apps_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_ingress_https" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_ingress_https_backend_set.name
  name                     = "openshift_cluster_ingress_https"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_apps_lb.id
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_api_backend_set_internal" {
  health_checker {
    protocol          = "HTTP"
    port              = 6080
    return_code       = 200
    url_path          = "/readyz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_api_backend"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_api_listener_internal" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_api_backend_set_internal.name
  name                     = "openshift_cluster_api_listener"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_set" {
  health_checker {
    protocol          = "HTTP"
    port              = 22624
    return_code       = 200
    url_path          = "/healthz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_infra-mcs"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set.name
  name                     = "openshift_cluster_infra-mcs"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22623
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_set_2" {
  health_checker {
    protocol          = "HTTP"
    port              = 22624
    return_code       = 200
    url_path          = "/healthz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_infra-mcs_2"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs_2" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_2.name
  name                     = "openshift_cluster_infra-mcs_2"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_int_lb.id
  port                     = 22624
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "openshift_cluster_infra-mcs_backend_set_api_2" {
  health_checker {
    protocol          = "HTTP"
    port              = 22624
    return_code       = 200
    url_path          = "/healthz"
    interval_ms       = 10000
    timeout_in_millis = 3000
    retries           = 3
  }
  name             = "openshift_cluster_infra-mcs_2"
  load_balancer_id = oci_load_balancer_load_balancer.openshift_api_lb.id
  policy           = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "openshift_cluster_infra-mcs-api_2" {
  default_backend_set_name = oci_load_balancer_backend_set.openshift_cluster_infra-mcs_backend_set_api_2.name
  name                     = "openshift_cluster_infra-mcs_2"
  load_balancer_id         = oci_load_balancer_load_balancer.openshift_api_lb.id
  port                     = 22624
  protocol                 = "TCP"
}
