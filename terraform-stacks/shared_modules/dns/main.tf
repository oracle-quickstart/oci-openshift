terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 6.12.0"
    }
  }
}

resource "oci_dns_zone" "openshift-public" {
  count          = var.create_public_dns ? 1 : 0
  compartment_id = var.compartment_ocid
  name           = var.zone_dns
  zone_type      = "PRIMARY"
  defined_tags   = var.defined_tags
  depends_on     = [var.op_lb_openshift_api_apps_lb_ip_addr, var.op_lb_openshift_api_int_lb_ip_addr]
}

# TODO - will need to be disabled (with some other variable(s)) in C3/PCA because private zones are not supported
resource "oci_dns_zone" "openshift-private" {
  count          = var.create_private_dns ? 1 : 0
  compartment_id = var.compartment_ocid
  name           = var.zone_dns
  scope          = "PRIVATE"
  view_id        = data.oci_dns_resolver.dns_resolver.default_view_id
  zone_type      = "PRIMARY"
  defined_tags   = var.defined_tags
  depends_on     = [var.op_lb_openshift_api_lb_ip_addr, var.op_lb_openshift_apps_lb_ip_addr, var.op_lb_openshift_api_int_lb_ip_addr]
}

resource "oci_dns_rrset" "openshift_api" {
  count           = var.create_public_dns ? 1 : 0
  domain          = "api.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-public[0].id

  items {
    domain = "api.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_api_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}

resource "oci_dns_rrset" "openshift_apps" {
  count           = var.create_public_dns ? 1 : 0
  domain          = "*.apps.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-public[0].id

  items {
    domain = "*.apps.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_apps_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}

resource "oci_dns_rrset" "openshift_api_int" {
  count           = var.create_public_dns ? 1 : 0
  domain          = "api-int.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-public[0].id

  items {
    domain = "api-int.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_api_int_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}

resource "oci_dns_rrset" "openshift_api_private" {
  count           = var.create_private_dns ? 1 : 0
  domain          = "api.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-private[0].id

  items {
    domain = "api.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_api_apps_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}

resource "oci_dns_rrset" "openshift_apps_private" {
  count           = var.create_private_dns ? 1 : 0
  domain          = "*.apps.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-private[0].id

  items {
    domain = "*.apps.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_api_apps_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}

resource "oci_dns_rrset" "openshift_api_int_private" {
  count           = var.create_private_dns ? 1 : 0
  domain          = "api-int.${var.cluster_name}.${var.zone_dns}"
  rtype           = "A"
  zone_name_or_id = oci_dns_zone.openshift-private[0].id

  items {
    domain = "api-int.${var.cluster_name}.${var.zone_dns}"
    rdata  = var.op_lb_openshift_api_int_lb_ip_addr
    rtype  = "A"
    ttl    = "3600"
  }
}
