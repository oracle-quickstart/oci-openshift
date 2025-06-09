## Installing OpenShift Virtualization on OCI

### Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)

### Overview

[OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/index) provides the scalable, enterprise-grade virtualization functionality in OpenShift. You can use it to manage virtual machines (VMs) exclusively or alongside container workloads. In collaboration with RedHat, OpenShift Virtualization on OCI is available as a Technical Preview (TP) with General Availability (GA) to follow.

### Prerequisites

OpenShift Virtualization requires an RWX-enabled CSI driver to enable certain features such as Live Migration. To support OpenShift Virtualization, we have made available a Limited Availability (LA) RWX-enabled version of our OCI CSI driver. Read more about this driver and how to install it [here](./RWX-LA.md).

For the best performance, it is recommended that you use Openshift Virtualization on a cluster with bare metal compute instances, and that you use Ultra High Performance (UHP) Block Volumes. The **v1.30.0-RWX-LA** CSI driver manifests include an additional `oci-bv-uhp` StorageClass that creates Ultra High Performance Block Volumes with 120 VPUs/GB by default.

For more information, see:
- [OCI - Bare Metal Compute Shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#baremetalshapes)
- [OCI - Ultra High Performance Block Volumes](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeultrahighperformance.htm)
- [RedHat - Planning a bare metal cluster for OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html-single/installing_on_bare_metal/index#virt-planning-bare-metal-cluster-for-ocp-virt_preparing-to-install-on-bare-metal)
- [RedHat - Planning and Installing OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/getting-started#planning-and-installing-virt_virt-getting-started)

### Limitations

The RWX-enabled OCI CSI driver is being made available as a Technical Preview in Limited Availability. Please be considerate of that when you choose what environments to deploy these in.

Be aware that the following limitations apply when using this driver:

1. ReadWriteMany accessMode is only available for Raw Block Volumes i.e. `volumeMode: Block`.
2. The maximum number of different instances a volume can be attached to is **32**.
3. The maximum number of volume attachments a single instance can support is **32**.
4. Block Volumes can only be attached to instances within the same Availability Domain.
5. A Block Volume's performance (vpusPerGB) is shared between all of it's attachments.
6. An Ultra High Performance Block Volume's performance is limited to 50,000 IOPS and 680 MB/s when attached to an OpenShift instance, regardless of the performance indicated by the Block Storage Service. OCI Block Volumes require the Oracle Cloud Agent and Block Volume Management plugin to be present on an instance to handle Multipath-enabled iSCSI attachments and support the highest levels of Block Volume performance. OpenShift instances on OCI do not currently meet these requirements.
7. The CSI driver can provision, attach, and mount Block Volumes to instances - it **can't** control read/write events between workloads and the underlying storage. To manage concurrent access and data integrity, users must rely on tools and software that are designed to handle this storage setup correctly.

### Installation

Follow the [installation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/installing#virt-installing-virt-operator_installing-virt) documentation from RedHat, but consider the following during and after installation:

1. OCI Block Volumes can only be attached to instances in the same Availability Domain. If you deployed your cluster in a region with multiple Availability Domains (e.g. us-phoenix-1), you need to ensure that at least one AD has multiple instances. When you get to Step 8 of the installation guide linked above, you need to configure the Infra and Workloads node placement by specifying the Availability Domain with at least 2 instances e.g. `topology.kubernetes.io/zone=PHX-AD-1`
2. After you have installed the OpenShift Virtualization operator and created your HyperConverged instance, you need to apply the following updates to your StorageClass' associated StorageProfiles:
```
oc patch storageprofile oci-bv --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
oc patch storageprofile oci-bv-encrypted --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
oc patch storageprofile oci-bv-uhp --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
```
3. If a StorageClass was not specified as the default, you'll need to set one. If you need the highest level of block volume performance, set `oci-bv-uhp` as the default:
```
oc patch storageclass oci-bv-uhp -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```
