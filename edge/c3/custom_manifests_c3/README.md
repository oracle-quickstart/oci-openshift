These manifest files are specifically designed for the Development Preview of OpenShift 4.16 at Oracle Cloud Compute@Customer(C3). They are used in the step: "Custom manifests", of provisioning an OpenShift cluster in RedHat's Hybrid Cloud Console / OpenShift UX.

The stringData content of the `oci-ccm-04-cloud-controller-manager-config.yaml` Secret in the `c3/custom_manifests_c3/manifests/oci-ccm.yml` file, as well as the stringData content of the `oci-csi-01-config.yaml` Secret in the `c3/custom_manifests_c3/manifests/oci-csi.yml` file, 
should be replaced with the output from running the `createInfraResources.tf` file.

Example:
```
stringData:
  cloud-provider.yaml: |
    useInstancePrincipals: true
    compartment: <compartment-ocid>
    vcn: <vcn-ocid>
    loadBalancer:
      subnet1: <subnet-ocid>
      securityListManagementMode: Frontend
      securityLists:
        <subnet-ocid>: <security-ocid>
    rateLimiter:
      rateLimitQPSRead: 20.0
      rateLimitBucketRead: 5
      rateLimitQPSWrite: 20.0
      rateLimitBucketWrite: 5
```


The stringData content of the `oci-ccm-C3-cert.yaml` Secret in the `c3/custom_manifests_c3/manifests/oci-ccm.yml` file, as well as the stringData content of the `oci-csi-C3-cert.yaml` Secret in the `c3/custom_manifests_c3/manifests/oci-csi.yml` file,
should be replaced with the C3 cert.


Example:
```
stringData:
  c3-cert.pem: |
    -----BEGIN CERTIFICATE-----
    your cert content
    -----END CERTIFICATE-----
```
