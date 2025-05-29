# Terraform Defined Resources for OpenShift on OCI

This directory contains Terraform stacks specifically designed for Red Hat OpenShift on Oracle Cloud Infrastructure. They can be used to provision OCI resources that support the creation and management of OpenShift clusters running on OCI. These stacks are typically applied using OCI Resource Manager Service (RMS).

⚠️ Important: You must run the create-attribution-tags stack before running any other stacks. This stack creates a tagNamespace and associated defined-tags (openshift-tags and openshift-resource) that are essential for all subsequent stacks to function correctly. Skipping this step may cause failures or unexpected behavior. You can skip this step if the tagNamespace and its associated defined-tags already exist.


## add-nodes

Create new instances to be added to an existing OpenShift cluster. Requires an OpenShift image file generated specifically for adding nodes.

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

## create-resource-attribution-tags

Openshift resource attribution tags used to categorize, organize, and track resource usage, ownership, billing, or compliance within OCI. These tags simplify resource management by providing clear metadata for reporting, auditing, and operational efficiency.  Example --> "defined-tags" - {"openshift-tags"- {"openshift-resource" - "openshift-resource-infra"} }.

⚠️ Note: Execute this stack only if the required tags do not already exist within your tenancy.

#### Default Attribution Tags

- **Tag NameSpace**
    - openshift-tags
- **Defined Tag Name**
    - openshift-resource

## create-cluster

Create the OCI resources for a new OpenShift cluster.

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
        - serves "api-int"
    - API and Applications
        - serves "api" and "*.apps"
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
    - Memory: 16 GB
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

## create-instance-role-tags

OCI tagging resources that are used to tag OpenShift cluster OCI resources. The tags are used to identify cluster-specific resources and should not be deleted while in use.

Please allow for ~10 minutes after creation before tagging resources with them. Some OCI Services take a lttle extra time to pick up newly created tags.

It is recommended but not required to create and reuse tags for your OpenShift clusters. All 'cluster' terraform stacks provision new tagging resources specific to your cluster by default, but can be configured to use existing tags.

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
