# Terraform Defined Resources for OpenShift on OCI

This directory contains Terraform stacks specifically designed for Red Hat OpenShift on Oracle Cloud Infrastructure. They can be used to provision OCI resources that support the creation and management of OpenShift clusters running on OCI. These stacks are typically applied using OCI Resource Manager Service (RMS). The most common use-case is to use the generic 'create-cluster' stack which defines all resources necessary to create an OpenShift cluster on OCI.


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

## create-cluster

Create the OCI resources for a new OpenShift cluster.

#### OCI Resources

- **Tag Namespace and Tags**
    - Tag Namespace
    - Defined Tags
        - "openshift-resource"
            - "openshift-resource-{cluster_name}"
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
        - "public"
        - "private"
        - "private_two"
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
    - Shape: VM.Standard.E4.Flex
    - OCPU: 4
    - Memory: 16 GB
    - Boot Volume
        - Size: 1024 GB
        - VPUs/GB: 100
- **Compute**
    - Count: 3
    - Shape: VM.Standard.E4.Flex
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

## create-tags

OCI tagging resources that are used to tag other OpenShift cluster OCI resources. The tags are used to identify cluster-specific resources and should not be deleted while in use.

Please allow for ~10 minutes after creation before tagging resources with them. Some OCI Services take a lttle extra time to pick up newly created tags.

It is recommended but not required to create and reuse tags for your OpenShift clusters. All 'cluster' terraform stacks provision new tagging resources specific to your cluster by default, but can be configured to use existing tags.

#### OCI Resources

- **Tag Namespace and Tags**
    - Tag Namespace
    - Defined Tags
        - "openshift-resource"
            - "openshift-resource-{cluster_name}"
        - "instance-role"
            - "control-plane"
            - "compute"
        - "boot-volume-type"
            - "PARAVIRTUALIZED"
            - "ISCSI"
