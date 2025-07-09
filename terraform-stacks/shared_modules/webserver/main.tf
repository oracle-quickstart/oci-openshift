terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.38.0"
    }
  }
}

# data "local_file" "webserver-setup" {
#   filename = "${path.module}/userdata/setup-webserver.sh"
# }

resource "oci_core_instance" "webserver" {
  count               = var.is_disconnected_installation ? 1 : 0
  availability_domain = var.webserver_availability_domain
  compartment_id      = var.webserver_compartment_ocid
  shape               = var.webserver_shape
  display_name        = var.webserver_display_name

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

  #   metadata = var.webserver_metadata
  metadata = {
    ssh_authorized_keys = var.public_ssh_key
    user_data = base64encode(templatefile("${path.module}/userdata/setup-webserver.sh.tpl", {
      openshift_installer_version = var.openshift_installer_version
      set_proxy                   = tostring(var.set_proxy)
      http_proxy                  = var.http_proxy
      https_proxy                 = var.https_proxy
      no_proxy                    = var.no_proxy
    }))
  }
}

output "webserver_public_ip" {
  value = try(oci_core_instance.webserver[0].public_ip, null)
}

output "webserver_private_ip" {
  value = try(oci_core_instance.webserver[0].private_ip, null)
}
