# Terraform Deployed Resources for OpenShift on OCI

This Terraform code provisions resources for an OpenShift cluster running on Oracle Cloud Infrastructure (OCI).

## Resources Created:

- **Availability Domain**: First availability domain for the compartment.
- **Tag Namespace and Tags**:
    - Namespace: "openshift"
    - Tag values: "master" and "worker"
- **Image Capabilities**:
    - Global Image Capability Schemas
    - Image Capability Schema for Openshift
    - Openshift Image Configuration
- **Shape Management**: Compute shapes for the Openshift image.
- **Network Configuration**:
    - VCN (Virtual Cloud Network)
    - Internet Gateway
    - NAT Gateway
    - Oracle Services
    - Service Gateway
    - Route Tables:
        - Public Routes
        - Private Routes
    - Security Lists:
        - Private Security List
        - Public Security List
    - Subnets:
        - Private Subnet
        - Public Subnet
- **Network Security Groups (NSGs) and Rules**:
    - NSGs:
        - Load balancers NSG
        - Cluster control plane NSG
        - Compute nodes NSG
- **Network Load Balancer (NLB)**
- **OCI Identity Resources**:
    - Dynamic groups
    - Policies
- **DNS Resources**:
    - oci_dns_zone
    - oci_dns_rrset (Two entries)
- **Compute Configurations**:
    - Master Instance Configuration
    - Worker Instance Configuration
- **Compute Pools**: Pools of master and worker nodes.

