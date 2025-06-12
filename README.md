# OpenShift on OCI (OSO)

This repository provides the tools and configuration needed to deploy and manage Red Hat OpenShift Container Platform clusters on Oracle Cloud Infrastructure (OCI). It includes:
* [Terraform stacks](/terraform-stacks/README.md) for provisioning the required OCI infrastructure.
* OpenShift and Kubernetes [manifest files](/custom_manifests/README.md) for installing and configuring clusters.

## Overview

Installing OpenShift clusters on OCI involves two main stages:

**1. Provisioning Infrastructure**

Before installing OpenShift clusters, you must set up the required OCI infrastructure including Virtual Cloud Netwoorks (VCNs), public and private subnets, compute instances (control plane and worker nodes), load balancers, IAM policies, and object storage buckets. You can provision infrastructure in two ways:

* **Using Terraform:** Create OCI resources using the Terraform stack provided in this repo or available via the OCI Console. This method is recommended for connected environments.

* **Manual Provisioning:** Manually create the resources using OCI Console and CLI. Use this method for disconnected or air-gapped environments, or if you can't use the OCI-provided Terraform due to policy restrictions.

**2. Installing and Configuring Cluster**

Deploying an OpenShift cluster on OCI combines actions performed in the Red Hat Hybrid Cloud Console and the OCI Console. You can install and configure OpenShift clusters on OCI using either the Red Hat's **Assisted Installer** or **Agent-based Installer**.

## Quick-Start Guide

### 1. Prerequisites

Before you begin, ensure you have: 

- A Red Hat account with access to Assisted Installer or Agent-based Installer.
- An OCI account with permissions to create and manage resources.
- An internet domain to serve the OpenShift Container Platform console that runs on cluster resources in OCI.
- An [SSH key pair](https://docs.oracle.com/en-us/iaas/Content/Compute/tutorials/first-linux-instance/overview.htm) for cluster installation.
- A pull secret provided from the Red Hat Hybrid Cloud Console. See [Using image pull secrets (Red Hat documentation)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/images/managing-images#using-image-pull-secrets).
- *(Optional)* A dedicated compartment for the cluster resources. You can also use an existing compartment.
- *(Optional)* An Object Storage bucket to store the discovery ISO image. You can also use an existing bucket.

⚠️ **Important**: Before creating the cluster, ensure you've executed the latest version of [create-attribution-tags](https://github.com/oracle-quickstart/oci-openshift/tree/main/terraform-stacks/create-resource-attribution-tags) stack. This ensures all necessary tags are available prior to cluster provisioning. You only need to run this for the `first cluster deployment`. Subsequent cluster deployments will not require this step, as the tags will already exist.

### 2. Installing OpenShift Clusters on OCI

 Follow the installation instructions for your preferred method:

**Assisted Installer**: Red Hat's Assisted Installer provides a simple web interface in the Red Hat Hybrid Cloud Console for cluster installation. This method is recommended for most users and requires an internet connection. See [Installing a Cluster with Red Hat's Assisted Installer](https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/installing-assisted.htm).

**Agent-based Installer**: This method equires you to create OCI resources manually in the OCI Console or use your own automation tools.

  * **Using Terraform:** Use the Terraform to provision the resources and then install the cluster. See [Installing a Cluster with Agent-based Installer Using Terraform](https://preview.content.oci.oracleiaas.com/en-us/iaas/Content/openshift-on-oci/agent-installer-using-stack.htm?bundle=22878&showfilteredtoc=true).

  * **Manually:** Manually provision the infrastructure and then install the cluster. See [Installing a Cluster with Agent-Based Installer Manually](https://preview.content.oci.oracleiaas.com/en-us/iaas/Content/openshift-on-oci/installing-agent.htm?bundle=22878&showfilteredtoc=true).

### 3. Post-Installation

 * Verify that your cluster is installed and running smoothly. Follow the instructions for your installation method:
  
   [Verifying cluster install - Assisted Installer(Red Hat documentation)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/installing_on_oci/installing-oci-assisted-installer#verifying-cluster-install-ai-oci_installing-oci-assisted-installer)
   
   [Verifying cluster install - Agent-based Installer (Red Hat documentation)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/installing_on_oci/installing-oci-agent-based-installer#verifying-cluster-install-oci-agent-based_installing-oci-agent-based-installer)
 * Apply any required Day 2 configurations. See [Adding Nodes to a Cluster](https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/adding-nodes.htm).

## Reference
**Oracle Documentation**
- [Overview of OpenShift Container Platform on OCI](https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm)

**Red Hat Documentation**
- [Installing a cluster on Oracle Cloud Infrastructure (OCI) by using the Assisted Installer](https://docs.openshift.com/container-platform/latest/installing/installing_oci/installing-oci-assisted-installer.html)
- [Installing a cluster on Oracle Cloud Infrastructure (OCI) by using the Agent-based Installer](https://docs.openshift.com/container-platform/latest/installing/installing_oci/installing-oci-agent-based-installer.html)
- [OSO Overview](https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm)
- [Connected deployments using Assisted Installer](https://docs.openshift.com/container-platform/latest/installing/installing_oci/installing-oci-assisted-installer.html)
- [Disconnected or air gapped deployments using Agent-based Installer](https://docs.openshift.com/container-platform/latest/installing/installing_oci/installing-oci-agent-based-installer.html)

## Contributing

This project welcomes contributions from the community. Before submitting a pull request, please [review our contribution guide](./CONTRIBUTING.md)

## Security

Please consult the [security guide](./SECURITY.md) for our responsible security vulnerability disclosure process

## License

Copyright (c) 2022 Oracle and/or its affiliates.

Released under the Universal Permissive License v1.0 as shown at
<https://oss.oracle.com/licenses/upl/>.
