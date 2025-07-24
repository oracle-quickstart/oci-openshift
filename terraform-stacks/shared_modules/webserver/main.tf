terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.38.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.12.1"
    }
  }
}

resource "oci_objectstorage_object" "agent_config" {
  bucket       = var.object_storage_bucket
  namespace    = var.object_storage_namespace
  object       = "${var.cluster_name}-agentBasedInstallation/agent-config.yaml"
  content      = var.agent_config
  content_type = "text/yaml"
}

resource "oci_objectstorage_object" "install_config" {
  bucket       = var.object_storage_bucket
  namespace    = var.object_storage_namespace
  object       = "${var.cluster_name}-agentBasedInstallation/install-config.yaml"
  content      = var.install_config
  content_type = "text/yaml"
}

resource "oci_objectstorage_object" "dynamic_custom_manifest" {
  bucket       = var.object_storage_bucket
  namespace    = var.object_storage_namespace
  object       = "${var.cluster_name}-agentBasedInstallation/openshift/dynamic-custom-manifest.yaml"
  content      = var.dynamic_custom_manifest
  content_type = "text/yaml"
}

resource "time_sleep" "wait_for_objects" {
  depends_on = [
    oci_objectstorage_object.agent_config,
    oci_objectstorage_object.install_config,
    oci_objectstorage_object.dynamic_custom_manifest
  ]
  create_duration = "30s"
}

resource "oci_core_instance" "webserver" {
  count               = var.is_disconnected_installation ? 1 : 0
  availability_domain = var.webserver_availability_domain
  compartment_id      = var.webserver_compartment_ocid
  shape               = var.webserver_shape
  display_name        = var.webserver_display_name

  defined_tags = {
    "${var.openshift_tag_namespace}.${var.openshift_tag_instance_role}"               = "control_plane"
    "${var.openshift_attribution_tag_namespace}.${var.openshift_attribution_tag_key}" = var.openshift_tag_openshift_resource_value
  }

  create_vnic_details {
    private_ip       = var.webserver_private_ip
    assign_public_ip = var.webserver_assign_public_ip
    subnet_id        = var.webserver_subnet_id
  }
  shape_config {
    memory_in_gbs = var.webserver_memory_in_gbs
    ocpus         = var.webserver_ocpus
  }
  source_details {
    source_id   = var.webserver_image_source_id
    source_type = var.webserver_source_type
  }

  metadata = {
    ssh_authorized_keys = var.public_ssh_key
    user_data = base64encode(templatefile("${path.module}/userdata/setup-webserver.sh.tpl", {
      openshift_installer_version    = var.openshift_installer_version
      set_proxy                      = tostring(var.set_proxy)
      http_proxy                     = var.http_proxy
      https_proxy                    = var.https_proxy
      no_proxy                       = var.no_proxy
      agent_install_dir              = "/home/opc/${var.cluster_name}-agentBasedInstallation"
      agent_config_object            = oci_objectstorage_object.agent_config.object
      install_config_object          = oci_objectstorage_object.install_config.object
      dynamic_custom_manifest_object = oci_objectstorage_object.dynamic_custom_manifest.object
      object_storage_namespace       = var.object_storage_namespace
      object_storage_bucket          = var.object_storage_bucket
      cluster_name                   = var.cluster_name
    }))
  }
}

output "webserver_public_ip" {
  value = try(oci_core_instance.webserver[0].public_ip, null)
}

output "webserver_private_ip" {
  value = try(oci_core_instance.webserver[0].private_ip, null)
}
