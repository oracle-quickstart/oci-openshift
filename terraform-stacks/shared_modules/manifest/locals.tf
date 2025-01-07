locals {
  common_config = <<-COMMONCONFIG
    useInstancePrincipals: true
    compartment: ${var.compartment_ocid}
    vcn: ${var.op_vcn_openshift_vcn}
    loadBalancer:
      subnet1: ${var.op_subnet}
      securityListManagementMode: Frontend
      securityLists: ${var.op_security_list}
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
      subnet1: ${var.op_subnet}
      securityListManagementMode: Frontend
      securityLists:
        ${var.op_security_list}
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
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
      subnet1: ${var.op_subnet}
      securityListManagementMode: Frontend
      securityLists:
        ${var.op_security_list}
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
---
  EOT

}
