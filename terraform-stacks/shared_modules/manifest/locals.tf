locals {
  common_config = <<-COMMONCONFIG
    useInstancePrincipals: true
    compartment: ${var.compartment_ocid}
    vcn: ${var.op_vcn_openshift_vcn}
    loadBalancer:
      subnet1: ${var.op_apps_subnet}
      securityListManagementMode: Frontend
      securityLists: ${var.op_apps_security_list}
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
    COMMONCONFIG

  oci_ccm_config_secret = <<EOT
# oci-ccm-04-cloud-controller-manager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: oci-cloud-controller-manager
  namespace: oci-cloud-controller-manager
stringData:
  cloud-provider.yaml: |
    useInstancePrincipals: true
    compartment: ${var.compartment_ocid}
    vcn: ${var.op_vcn_openshift_vcn}
    loadBalancer:
      subnet1: ${var.op_apps_subnet}
      securityListManagementMode: Frontend
      securityLists:
        ${var.op_apps_security_list}
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
    tags:
      loadBalancer:
        defined:
          openshift-tags:
            openshift-resource: openshift-resource-infra
      blockVolume:
        defined:
          openshift-tags:
            openshift-resource: openshift-resource-infra
---
  EOT

  oci_csi_config_secret = <<EOT
# oci-csi-01-config.yaml
apiVersion: v1
kind: Secret
metadata:
  creationTimestamp: null
  name: oci-volume-provisioner
  namespace: oci-csi
stringData:
  config.yaml: |
    useInstancePrincipals: true
    compartment: ${var.compartment_ocid}
    vcn: ${var.op_vcn_openshift_vcn}
    loadBalancer:
      subnet1: ${var.op_apps_subnet}
      securityListManagementMode: Frontend
      securityLists:
        ${var.op_apps_security_list}
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
    tags:
      loadBalancer:
        defined:
          openshift-tags:
            openshift-resource: openshift-resource-infra
      blockVolume:
        defined:
          openshift-tags:
            openshift-resource: openshift-resource-infra
---
  EOT

  agent_config = <<EOT
apiVersion: v1alpha1
metadata:
  name: ${var.cluster_name}
  namespace: ${var.cluster_name}
rendezvousIP: ${var.rendezvous_ip}
${var.is_disconnected_installation ? "bootArtifactsBaseURL: http://${var.webserver_private_ip}" : ""}
  EOT

  install_config = <<EOT
apiVersion: v1
metadata:
  name: ${var.cluster_name}
baseDomain: ${var.zone_dns}
networking:
  clusterNetwork:
    - cidr: 10.128.0.0/14
      hostPrefix: 23
  networkType: OVNKubernetes
  machineNetwork:
    - cidr: ${var.vcn_cidr}
  serviceNetwork:
    - 172.30.0.0/16
compute:
  - architecture: amd64
    hyperthreading: Enabled
    name: worker
    replicas: ${var.compute_count}
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  replicas: ${var.control_plane_count}
platform:
  external:
    platformName: oci
    cloudControllerManager: External
${trimspace(var.set_proxy ? <<-PROXY
proxy:
  httpProxy: ${var.http_proxy}
  httpsProxy: ${var.https_proxy}
  noProxy: ${var.no_proxy},${var.vcn_cidr}
PROXY
: "")}
sshKey: '${var.public_ssh_key}'
pullSecret: '${var.redhat_pull_secret}'
  EOT

}
