# Terraform Defined Resources for OpenShift on OCI

#### Terraform Stacks
- [create-resource-attribution-tags](#create-resource-attribution-tags)
- [create-instance-role-tags](#create-instance-role-tags)
- [create-cluster](#create-cluster)
- [add-nodes](#add-nodes)

---

This directory contains Terraform stacks specifically designed for Red Hat OpenShift on Oracle Cloud Infrastructure. They can be used to provision OCI resources that support the creation and management of OpenShift clusters running on OCI. These stacks are typically applied using OCI Resource Manager Service (RMS).

⚠️ Important: You must create the OpenShift resource attribution tags first (using the [create-resource-attribution-tags](#create-resource-attribution-tags) stack) before you can create clusters or add nodes using our other stacks. Skipping this step may cause failures or unexpected behavior.

---
---

## create-resource-attribution-tags

OpenShift resource attribution tags used to categorize, organize, and track resource usage, ownership, billing, or compliance within OCI. This stack creates a Tag Namespace and Defined Tag that are applied to all future OpenShift resources. These tags simplify resource management by providing clear metadata for reporting, auditing, and operational efficiency.

Example:
```
{"openshift-tags": {"openshift-resource": "openshift-resource-infra"}
```

⚠️ Note: Apply this stack only if the required tagging resources do not already exist within your tenancy.

⚠️ Note: For customers creating OpenShift resources on their C3 devices, these tagging resources must exist in your home region tenancy.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-openshift/releases/latest/download/create-resource-attribution-tags.zip)

#### OCI Resources

- **Tag Namespace**
    - `openshift-tags`
- **Defined Tag**
    - `openshift-resource`

---
---

## create-instance-role-tags

OCI tagging resources that are used to tag OpenShift cluster OCI resources. The tags are used to identify cluster-specific resources and should not be deleted while in use.

Please allow for ~10 minutes after creation before tagging resources with them. Some OCI Services take a lttle extra time to pick up newly created tags.

⚠️ Note: This stack is *optional*. It is recommended but not required to create and reuse tags for your OpenShift clusters. All 'cluster' terraform stacks provision new tagging resources specific to your cluster by default, but can be configured to use existing tags to avoid delays caused by waiting for tags.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-openshift/releases/latest/download/create-instance-role-tags.zip)

#### OCI Resources

- **Tag Namespace and Tags**
    - Tag Namespace
    - Defined Tags
        - "instance-role"
            - "control-plane"
            - "compute"
        - "boot-volume-type"
            - "PARAVIRTUALIZED"
            - "ISCSI"

---
---

## create-cluster

Create the OCI resources for an OpenShift cluster on OCI and facilitate the installation of OpenShift.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-openshift/releases/latest/download/create-cluster.zip)

#### Default Node Configuration

- **Control Plane**
    - Count: 3
    - Shape: VM.Standard.E5.Flex
    - OCPU: 4
    - Memory: 24 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 100
- **Compute**
    - Count: 3
    - Shape: VM.Standard.E5.Flex
    - OCPU: 6
    - Memory: 16 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 30

#### OCI Resources

- **Tag Namespace and Tags**
    - Tag Namespace
    - Defined Tags
        - "instance-role"
            - "control-plane"
            - "compute"
        - "boot-volume-type"
            - "PARAVIRTUALIZED"
            - "ISCSI"
- **IAM**
    - Dynamic groups
        - "{cluster_name}_control_plane_nodes"
        - "{cluster_name}_compute_nodes"
    - Policies
        - "{cluster_name}_control_plane_nodes"
- **Networking**
    - VCN (Virtual Cloud Network)
    - Internet Gateway
    - NAT Gateway
    - Oracle Services
    - Service Gateway
    - Route Tables
        - Public Routes
        - Private Routes
    - Security Lists
        - Private Security List
        - Public Security List
    - Subnets
        - Private Subnet
            - Private Subnet for OCP
            - Private Subnet for Bare Metal
        - Public Subnet
    - NSGs (Network Security Groups)
        - "cluster-lb-nsg"
        - "cluster-controlplane-nsg"
        - "cluster-compute-nsg"
- **DNS**
    - oci_dns_zone
    - oci_dns_rrset
        - api
        - api-int
        - *.apps
- **Load Balancers**
    - API Internal
        - "api-int"
    - API
        - "api"
    - Application
        - "*.apps"
- **Compute Image**
    - Global Image Capability Schemas
    - Image Capability Schema for OpenShift
    - OpenShift Image Configuration
- **Compute Instances**
    - Control Plane nodes
    - Compute nodes

### Example Cluster Configurations
---

#### High-Availability VMs (Default)

- **Control Plane**
    - Count: 3
    - Shape: VM.Standard.E5.Flex
    - OCPU: 4
    - Memory: 24 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 100
- **Compute**
    - Count: 3
    - Shape: VM.Standard.E5.Flex
    - OCPU: 6
    - Memory: 16 GB
    - Boot Volume
        - Size: 100 GB
        - VPUs/GB: 30

#### Compact Bare Metal

- **Control Plane**
    - Count: 3
    - Shape: BM.Standard3.64
    - OCPU: 64
    - Memory: 1024 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 100
- **Compute**
    - Count: 0

#### Single Node OpenShift Bare Metal (SNO)

- **Control Plane**
    - Count: 1
    - Shape: BM.Standard3.64
    - OCPU: 64
    - Memory: 1024 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 100
- **Compute**
    - Count: 0

---
---

## add-nodes

Create new instances to be added to an existing OpenShift cluster. Requires an OpenShift image file generated specifically for adding nodes.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/oracle-quickstart/oci-openshift/releases/latest/download/add-nodes.zip)

#### OCI Resources

- **Load Balancers**
    - Updated backend sets
- **Compute Image**
    - Global Image Capability Schemas
    - Image Capability Schema for OpenShift
    - OpenShift Image Configuration
- **Compute Instances**
    - Control Plane nodes
    - Compute nodes
---
