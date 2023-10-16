These manifest files are specifically designed for the Development Preview of OpenShift 4.14 at Oracle Cloud Infrastructure (OCI). They are used in the 6th step: "Custom manifests", of provisioning an OpenShift cluster in RedHat's Hybrid Cloud Console / OpenShift UX. 

The "oci_ccm_config" output of the RMS stack job (used to create the OCI cluster for OpenShift) should be appended into oci-ccm-04-cloud-controller-manager-config.yaml.

example:
```
stringData:
    cloud-provider.yaml: |
        useInstancePrincipals: true
        compartment: ocid1.compartment.oc1..aaaaaaaa3pnouqmely2hz2w3bval4kxvca6ahfxbq3whr6x74vnhhrb7icuq
        vcn: ocid1.vcn.oc1.iad.amaaaaaafsiujfyafl2o3bs7weguimvpsrgo3vjxux6obrnxvvmortv5k4bq
        loadBalancer:
        subnet1: ocid1.subnet.oc1.iad.aaaaaaaaztoytdvpoebsdrtriwh65pfzkmepb22dftqqplqbjwgroa3sskaa
        securityListManagementMode: Frontend
        securityLists:
        ocid1.subnet.oc1.iad.aaaaaaaaztoytdvpoebsdrtriwh65pfzkmepb22dftqqplqbjwgroa3sskaa: ocid1.securitylist.oc1.iad.aaaaaaaacnp3cdn4zt7232xjxaxzuij62aizsiwqjwn237zna4qoov4ilg6a
        rateLimiter:
        rateLimitQPSRead: 20.0
        rateLimitBucketRead: 5
        rateLimitQPSWrite: 20.0
        rateLimitBucketWrite: 5
```
