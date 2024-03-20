# Terraform Deployed Resources for OpenShift on OCI

This Terraform code is specifically designed for the OpenShift on Oracle Cloud Infrastructure (OCI). It provisions resources for an OpenShift cluster running on Oracle Cloud Infrastructure.

See the following for installation instructions:

**OpenShift 4.14 on Oracle Cloud Infrastructure (OCI) [Technology Preview]**
- Connected deployments using Assisted Installer: https://docs.openshift.com/container-platform/4.14/installing/installing_oci/installing-oci-assisted-installer.html
- Disconnected or air gapped deployments using Agent-based Installer: https://docs.openshift.com/container-platform/4.14/installing/installing_oci/installing-oci-agent-based-installer.html

**OpenShift 4.15 on Oracle Cloud Infrastructure (OCI) [Technology Preview]**
- Connected deployments using Assisted Installer: https://docs.openshift.com/container-platform/4.15/installing/installing_oci/installing-oci-assisted-installer.html
- Disconnected or air gapped deployments using Agent-based Installer: https://docs.openshift.com/container-platform/4.15/installing/installing_oci/installing-oci-agent-based-installer.html

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

