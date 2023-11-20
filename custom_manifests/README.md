These manifest files are specifically designed for the Development Preview of OpenShift 4.14 at Oracle Cloud Infrastructure (OCI). They are used in the 6th step: "Custom manifests", of provisioning an OpenShift cluster in RedHat's Hybrid Cloud Console / OpenShift UX. 

cloud-provider.yaml in oci-ccm.yml and config.yaml in oci-csi.yml should be replaced by the output of the RMS stack job. 

example:
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
