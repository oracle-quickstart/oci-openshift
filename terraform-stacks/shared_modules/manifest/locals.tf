locals {
  default_oci_driver_image = "ghcr.io/oracle/cloud-provider-oci:v1.32.0"

  oci_image_sources = {
    "v1.30.0"     = "ghcr.io/oracle/cloud-provider-oci:v1.30.0"
    "v1.32.0"     = "ghcr.io/oracle/cloud-provider-oci:v1.32.0"
    "v1.32.0-UHP" = "ghcr.io/dfoster-oracle/cloud-provider-oci-amd64:v1.32.0-UHP-LA"
  }

  oci_csi = templatefile("${path.module}/manifest-templates/01-oci-csi.yml.tpl", {
    region_metadata    = var.region_metadata
    oci_driver_version = var.oci_driver_version
    oci_image_source   = lookup(local.oci_image_sources, var.oci_driver_version, local.default_oci_driver_image)
  })

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
    cloudControllerManager: External${trimspace(var.set_proxy ? <<-PROXY
proxy:
  httpProxy: ${var.http_proxy}
  httpsProxy: ${var.https_proxy}
  noProxy: ${var.no_proxy},${var.vcn_cidr}
PROXY
: "")}
sshKey: '${var.public_ssh_key}'
pullSecret: '${var.redhat_pull_secret}'
  EOT

oca_yaml = <<EOT
# oci-oca-00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: oci-agent
  labels:
    "pod-security.kubernetes.io/enforce": "privileged"
    "pod-security.kubernetes.io/audit": "privileged"
    "pod-security.kubernetes.io/warn": "privileged"
    "openshift.io/run-level": "0"
---
# oci-oca-01-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: oci-agent
  namespace: oci-agent
---
# oci-oca-02-daemon-set.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: oci-agent-ds
  namespace: oci-agent
spec:
  selector:
    matchLabels:
      name: oci-agent
  template:
    metadata:
      labels:
        name: oci-agent
    spec:
      hostNetwork: true
      serviceAccountName: oci-agent
      tolerations:
        - key: "node-role.kubernetes.io/control-plane"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
        - key: "node.kubernetes.io/not-ready"
          operator: "Exists"
          effect: "NoSchedule"
      containers:
      - image: ${var.oca_image_pull_link}
        name: oci-agent-pod-01
        securityContext:
          privileged: true
---
  EOT
}
