## Installing OpenShift Virtualization on OCI

### Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)

### Overview

[OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/index) provides the scalable, enterprise-grade virtualization functionality in OpenShift. You can use it to manage virtual machines (VMs) exclusively or alongside container workloads. In collaboration with RedHat, OpenShift Virtualization on OCI is available as a Technical Preview (TP) with General Availability (GA) to follow.

### Prerequisites

OpenShift Virtualization requires an RWX-enabled CSI driver to enable certain features such as Live Migration. The OCI CSI driver now has a Limited Availability (LA) RWX-enabled version. Read more about this driver and how to install it [here](./RWX-LA.md).

It is recommended that you install Openshift Virtualization on a bare metal cluster. See [Planning a bare metal cluster for OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_bare_metal/index#virt-planning-bare-metal-cluster-for-ocp-virt_preparing-to-install-on-bare-metal) and [Planning and Installing OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/getting-started#planning-and-installing-virt_virt-getting-started) for more information.

### Installation

Though you can mostly follow the installation steps on [this](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/installing#virt-installing-virt-operator_installing-virt) page, there are some extra considerations when installing OpenShift Virtualization on OCI.

Please note the following:

1. OCI Block Volumes can only be attached to instances in the same Availability Domain. If you deployed your cluster in a region with multiple Availability Domains (e.g. us-phoenix-1), you need to ensure that at least one AD has multiple instances. When you get to Step 8 of the installation guide linked above, you need to configure the Infra and Workloads node placement by specifying the Availability Domain with at least 2 instances e.g. `topology.kubernetes.io/zone=PHX-AD-1`
2. After you have installed the OpenShift Virtualization operator and created your HyperConverged instance, you need to apply the following changes to your cluster:
```
oc patch storageclass oci-bv -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
oc patch storageprofile oci-bv --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
oc patch storageprofile oci-bv-encrypted --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
```
