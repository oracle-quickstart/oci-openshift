# OpenShift Virtualization on OCI

- [Prerequisites](#prerequisites)
- [Limits and Considerations](#limitations-and-considerations)
- [Installation](#installation)

[OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/index) provides scalable, enterprise-grade virtualization in OpenShift. You can use it to manage virtual machines (VMs) exclusively or alongside container workloads. Another use-case for OpenShift Virtualization is as a migration destination for VMs moving from vSphere to OpenShift using the Migration Toolkit for Virtualization.

In collaboration with Red Hat and their Virtualization team, OpenShift Virtualization is available for OpenShift on OCI.

For more information, see:
- [Red Hat - Planning and Installing OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/getting-started#planning-and-installing-virt_virt-getting-started)
- [Red Hat - Migration Toolkit for Virtualization](https://developers.redhat.com/products/mtv/overview)

## Prerequisites

For optimal performance, Openshift Virtualization should be used on clusters with Bare Metal compute nodes.

OpenShift Virtualization features such as Live Migration (node to node migration) require the underlying storage to have RWX capabilities. OCI CSI drivers [**v1.32.0**](https://github.com/oracle/oci-cloud-controller-manager/releases/tag/v1.32.0) and later have this capability.

We also recommend that you use Ultra High Performance Raw Block Volumes (UHP RBVs). UHP means a performance level of 30+ VPUs/GB, which means more IOPS and throughput (up to 50,000 IOPS and 680 MB/s) than the default Balanced setting for Block Volumes (10 VPUs/GB). A Raw Block Volume is a volume that has been attached as a block device. The volume is not formatted or mounted with a filesystem, but the lack of a filesystem results in higher performance storage (if the application is designed to work with it).

> [!NOTE]
> UHP RBVs are only available in a [forked](https://github.com/dfoster-oracle/oci-cloud-controller-manager/tree/dfoster/v1.32.0-beta) version of the [latest oci-cloud-controller-manager Release](https://github.com/oracle/oci-cloud-controller-manager/releases/latest), but the feature will be incorporated into the official driver at a later time.

For more information, see:
- [oci-openshift - STORAGE.md](/docs/STORAGE.md)
- [Red Hat - Planning a bare metal cluster for OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/installing_on_bare_metal/index#virt-planning-bare-metal-cluster-for-ocp-virt_preparing-to-install-on-bare-metal)
- [OCI - OpenShift on OCI: Supported Shapes](https://docs.oracle.com/en-us/iaas/Content/openshift-on-oci/overview.htm#supported-shapes)
- [OCI - Bare Metal Compute Shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm#baremetalshapes)
- [OCI - Ultra High Performance Block Volumes](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeultrahighperformance.htm)

## Limitations and Considerations

Be aware of OCI CSI driver [storage limitations and considerations](./STORAGE.md#limitations-and-considerations).

Also be aware of the following with respect to OpenShift Virtualization:

1. Ultra High Performance Raw Block Volumes (UHP RBVs) are available as a beta feature.

2. In this initial beta phase for the UHP RBV feature, Block Volume performance is limited to 50,000 IOPS and 680 MB/s regardless of the performance indicated by the Block Storage Service.
    - OCI Block Volumes require the Oracle Cloud Agent and Block Volume Management plugin to be present on an instance to handle Multipath-enabled iSCSI attachments and support the highest levels of Block Volume performance. OpenShift instances on OCI do not currently meet these requirements.

3. The minimum size for OCI Block Volumes is 50 GB.
    - If your VM image is less than 50 GB, a 50 GB Block Volume will be used.

4. The maximum number of Block Volume attachments a single instance can have is **32***.
    - Since each VM is backed by a single Block Volume, you can only have up to 32 VMs running on a single instance at a time since each VM needs its Block Volume attached to the instance it is running on.
    - You can use a different storage solution such as [OpenShift Data Foundation](https://www.redhat.com/en/technologies/cloud-computing/openshift-data-foundation) (ODF) for your OpenShift Virtualization environment to circumvent this limitation, but using ODF to support OpenShift Virtualization on OCI has not been certified by the Red Hat Virtualization team.

5. Block Volumes can only be attached to instances within the same Availability Domain (AD).
    - At least 2 instances in the same AD are required for the Live Migration feature of OpenShift Virtualization. This is a consideration when creating your cluster in a multi-AD region.
        - (Recommended) - Specify a [Node Selection or Affinity](https://www.redhat.com/en/blog/node-selection-and-affinity-for-virtual-machines-in-openshift) for infra and workloads when configuring your OpenShift Virtualization HyperConverged Operator to force OpenShift Virtualization to only use instances in the same AD e.g. `topology.kubernetes.io/zone=PHX-AD-1`
        - Set `distribute_compute_instances_across_ads` to false in the Terraform variables when provisioning your instances.

## Installation

### Using the UHP CSI Driver
The UHP-enabled OCI CSI driver is available when installing a cluster using our create-cluster Terraform stack (>v1.4.0) --- set `oci_driver_version`=[v1.32.0-UHP](/custom_manifests/oci-ccm-csi-drivers/v1.32.0-UHP/) and the `dynamic_custom_manifest` output will reference the UHP-enabled CSI driver container images:

```
ghcr.io/dfoster-oracle/cloud-provider-oci-amd64:v1.32.0-beta (default)
ghcr.io/dfoster-oracle/cloud-provider-oci-arm64:v1.32.0-beta
```

The [v1.32.0-UHP](/custom_manifests/oci-ccm-csi-drivers/v1.32.0-UHP/) manifests also include a new default StorageClass for UHP Block Volumes:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: oci-bv-uhp
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: blockvolume.csi.oraclecloud.com
parameters:
  oci.oraclecloud.com/initial-defined-tags-override: '{"openshift-tags": {"openshift-resource": "openshift-virtualization"}}'
  vpusPerGB: "80"
volumeBindingMode: Immediate
allowVolumeExpansion: true
reclaimPolicy: Delete
```

> [!TIP]
> You can also [update your existing cluster](/docs/STORAGE.md#to-upgradechange-oci-csi-driver-version-on-an-existing-openshift-cluster) with the UHP CSI driver.

---

### Installing OpenShift Virtualization
1. Follow the [installation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/installing#virt-installing-virt-operator_installing-virt) documentation from Red Hat to install the OpenShift Virtualization operator.

2. After you have installed the OpenShift Virtualization operator and created your HyperConverged instance, verify the StorageProfiles created by HyperConverged and [update](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/storage#virt-configuring-storage-profile) them if needed:
    ```bash
    oc patch storageprofile oci-bv-uhp --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteMany","ReadWriteOnce"], "volumeMode": "Block"}], "cloneStrategy": "csi-clone"}}'
    ```

3. You must have a **default** StorageClass for OpenShift Virtualization. If no StorageClass is annotated as the **default**, you can annotate/patch an existing StorageClass. For Ultra High Performance (UHP) Block Volumes, use `oci-bv-uhp` from the [Using the UHP CSI Driver](#using-the-uhp-csi-driver):

    Annotate it if necessary:
    ```bash
    oc patch storageclass oci-bv-uhp -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
    ```

4. The OCI CSI driver supports snapshotting, and if you want to be able to clone VMs or perform snapshot/restore operations, you must have a **default** `VolumeSnapshotClass`. The `oci-snapshot` `VolumeSnapshotClass` is annotated as the **default** and included in the `dynamic_custom_manifest` output from `create-cluster` (**>=v1.4.2**).

    If you are missing a `VolumeSnapshotClass` and need to add one to an existing cluster, review the following manifest and apply it to your cluster:

    ```yaml
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshotClass
    metadata:
      name: oci-snapshot
      annotations:
        snapshot.storage.kubernetes.io/is-default-class: "true"
    driver: blockvolume.csi.oraclecloud.com
    parameters:
      backupType: full
    deletionPolicy: Delete
    ```

    Apply it with:

    ```bash
    oc apply -f oci-snapshot.yaml
    ```

For more details, see [STORAGE.md - Enabling VolumeSnapshotClass](/docs/STORAGE.md#enabling-volumesnapshotclass).
