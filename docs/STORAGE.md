# Cloud Storage for OpenShift Clusters on OCI

Your containers and virtual machines in OpenShift require a seamless, optimized, and performant persistent storage solution. To this end, we provide our **OCI Container Storage Interface (CSI) driver**. The OCI CSI driver can dynamically provision cloud storage and make it available to applications running in your cluster.

In collaboration with the Oracle Kubernetes Engine (OKE) team who own and maintain the open source [oci-cloud-controller-manager](https://github.com/oracle/oci-cloud-controller-manager) repository (which includes the OCI CSI driver), we have adapted the drivers for OpenShift on OCI and we are continuing to add new features and enhancements for both teams.

The default storage option is the [OCI Block Volume Service](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm), but the driver is also compatible with [OCI File Storage](https://docs.oracle.com/en-us/iaas/Content/File/Concepts/filestorageoverview.htm) (FSS).

Read more about the OCI CSI driver in the context of Oracle Kubernetes Engine below:
- [OCI - Setting Up Storage for Kubernetes Clusters](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingpersistentvolumeclaim.htm)


## Available Features (Block Volume)

| Category                 | Options                    | Mode: `Filesystem` | Mode: `Block` |
|------------------------------|------------------------------|----------------------|----------------------------|
| **Lifecycle Management**     | Creation & Deletion of Volumes | ✅ | ✅ |
|                              | Volume Expansion               | ✅                   | ✅                         |
| **Volume Attachment Types**  | iSCSI                          | ✅                   | ✅                         |
|                              | Paravirtualized                | ✅                   | ✅                         |
| **[Performance Tiers](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeperformance.htm)** (vpusPerGB)       | Ultra High Performance (30+)        | ✅                   | ☑️ (beta) |
|                              | Higher Performance (20)             | ✅                   | ✅  |
|                              | Balanced (10) - default                  | ✅                  | ✅ |
|                              | Lower Cost (0)                 | ✅                   | ✅                         |
| **Storage Features**         | Snapshotting                   | ✅                   | ✅                         |
|                              | Encryption                     | ✅                   | ✅                         |
|                              | Cloning                        | ✅                   | ✅                         |
| **[Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)**          | ReadWriteOnce | ✅ |✅ |
| | ReadOnlyMany | 🔳 | ✅ |
| | ReadWriteMany | 🔳 | ✅ |

## OCI CSI Driver Components

The [manifests](/custom_manifests/manifests/01-oci-csi.yml) for the OCI CSI driver include the following Kubernetes Resource definitions:

| **Resource**           | **Name**              |**Description**                           | **Notes** |
|-------------------------|------------------------------|------------------------------------| --|
| ⭐ **Namespace**           | `oci-csi` | Isolates OCI CSI components within the cluster.  | It has specific security and labeling to enable certain cluster operations. |
| ⭐ **Deployment** | `csi-oci-controller` | Deploys the `oci-csi-controller-driver` and other CSI-related containers. | Responsible for storage provisioning, attachment, resizing, and snapshotting. |
| ⭐ **DaemonSet** | `csi-oci-node` | Deploys the `oci-csi-node-driver` to all worker nodes. | Responsible for mounting storage and making it available to worker nodes. |
| ⭐ **Secret** | `oci-volume-provisioner` | Contains OCI configuration, including instance principals and rate limits. | ❗Contains [placeholder values](https://github.com/oracle-quickstart/oci-openshift/blob/main/custom_manifests/manifests/01-oci-driver-configs.yml)❗ (view [Prerequisites](#prerequisites))          |
| ⭐ **StorageClass**    | `oci-bv` (default)| Defines the default OCI Block Volume storage option. | |
| | `oci-bv-encrypted`| An Encrypted OCI Block Volume storage option. | Paravirtualized attachments only. Requires extra customer setup. |
| **VolumeSnapshotClass** | `oci-snapshot` *Disabled by default* | The CSI driver supports basic OCI Block Volume Snapshotting, but the `VolumeSnapshotClass` is **not installed by default** for compatibility reasons. If you require volume snapshots or VM cloning, you must create the `VolumeSnapshotClass` manually after installation. See [Enabling VolumeSnapshotClass](#enabling-volumesnapshotclass) below. |
| **CSIDriver** | `blockvolume.csi.oraclecloud.com` | Declares support for OCI Block Volumes. | |
| | `fss.csi.oraclecloud.com` | Declares support for File Storage Service (FSS). |
| **ServiceAccount** | `csi-oci-node-sa` | Cluster RBAC for the driver. | |
| **ClusterRole** | `csi-oci` | Cluster RBAC for the driver. | |
| **ClusterRoleBinding** | `csi-oci-binding` | Cluster RBAC for the driver. | |
| **ConfigMap** | `oci-csi-iscsiadm` | A script for managing `iscsiadm` operations. |
| | `oci-fss-csi` | A script for FSS mounting operations. |

---
## Limitations and Considerations

Be aware of the following when using the OCI CSI driver:

1. Block Volume volumes can be created in sizes ranging from 50 GB to 32 TB in 1 GB increments. By default, Block Volume volumes are 1 TB.
2. The maximum number of Block Volume attachments a single instance can have is **32** attached block volumes for all shapes, except for the following VM shapes which have a limit of 16 paravirtualized-attached block volumes:
    - VM.Standard2.8
    - VM.DenseIO2.8
    - VM.Standard.E2.8
    - VM.Standard.E3.Flex
    - VM.Standard.E4.Flex
    - VM.Standard.A1.Flex
    - VM.Optimized3.Flex
3. Block Volumes have an Availability Domain (AD) and can only be attached to instances within the same AD.
4. The maximum number of different instances a Block Volume can be attached to is **32**.
5. A Block Volume's performance (vpusPerGB) is shared between all attachments.
6. The OCI CSI driver can provision, attach, and mount Block Volumes to instances - it **does not** manage read/write events between your workloads and the underlying storage. Other software layers manage concurrent access and maintain data integrity.

Review the Block Volume documentation below for more information:
- [OCI - Capabilities and Limits](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm#Capabil)
- [OCI - Performance Limitations and Considerations](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeperformance.htm#limits)
- [OCI - FAQ](https://www.oracle.com/cloud/storage/block-volumes/faq/)


## Using the OCI CSI driver

### Prerequisites

If you are using our Terraform to provision cluster resources and generate the `dynamic_custom_manifest` output, there are no extra steps required. Move on to [Deployment](#Deployment) or view [Examples](#examples).

Consider the following if you are not using Terraform or for general debugging:
1. The Secrets in [01-oci-driver-configs.yml](/custom_manifests/manifests/01-oci-driver-configs.yml), `oci-volume-provisioner` and `oci-cloud-controller-manager` allow the CSI and CCM drivers to interact with and create resources for your cluster. They initially contain placeholder values and must be configured before use. If using our Terraform to provision cluster resources, the `dynamic_custom_manifest` output includes these Secrets already configured. If you are manually provisioning OCI resources, you must update the Secret with the necessary values yourself. View provider config examples [here](https://github.com/oracle/oci-cloud-controller-manager/blob/master/manifests/provider-config-instance-principals-example.yaml).

2. To allow the CSI driver to operate on the OCI resources for your cluster, IAM Policies must be created in your tenancy which give access to a Dynamic Group comprised of the instances on which the CSI components are deployed. If you are using our Terraform to provision resources, the necessary [Dynamic Groups](/terraform-stacks/shared_modules/iam/dynamic_group.tf) and [Policies](/terraform-stacks/shared_modules/iam/policy.tf) are created for you.

Read more about these OCI IAM resources below:
- [OCI - IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm)
- [OCI - Dynamic Groups](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm)
- [OCI - Block Volume Policies](https://docs.oracle.com/en-us/iaas/Content/Block/blockvolumes.htm#blockvolumes__iam)
- [OCI - File System Policies](https://docs.oracle.com/en-us/iaas/Content/File/Concepts/filestorageoverview.htm#auth)
- [OCI - Keys and Vault Policies](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm#authentication)

### Deployment

The manifests containing the OCI CSI driver are typically applied to an OpenShift cluster during installation via [custom_manifests](/custom_manifests/manifests/01-oci-csi.yml) supplied by you during setup.

If you are using our Terraform to provision cluster resources, use the `dynamic_custom_manifest` output as the only custom_manifest during cluster installation. You can set the `oci_driver_version` variable when using the Terraform to generate the `dynamic_custom_manifest` output with the specified driver version. By default, the latest GA [version](https://github.com/oracle/oci-cloud-controller-manager/releases/latest) is used.

View the supported driver versions in [custom_manifests/oci-ccm-csi-drivers](/custom_manifests/oci-ccm-csi-drivers).

#### To upgrade/change OCI CSI driver version on an existing OpenShift cluster


1. Find the version of the oci-ccm-csi-driver manifests you need e.g. [**v1.32.0**](/custom_manifests/oci-ccm-csi-drivers/v1.32.0)

2. Apply the changes manually or reapply the entire manifest with the following command:

    ```bash
    oc apply -f custom_manifests/oci-ccm-csi-drivers/v1.32.0/01-oci-csi.yml
    ```

#### Enabling VolumeSnapshotClass

The OCI CSI driver supports snapshotting via `VolumeSnapshotClass`, but this class is **not installed by default**.

**To use features that require volume snapshots (such as VM cloning with OpenShift Virtualization)**, you must create the following manifest post-installation:

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
oc apply -f <your-volumesnapshotclass-file>.yaml
```

If you are using OpenShift Virtualization, please also see the relevant step in [openshift-virtualization.md](/docs/openshift-virtualization.md).

## Examples

### Block Volume - Filesystem Mode
**PersistentVolumeClaim**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oci-bv-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
```
**Pod**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: my-container
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: my-volume
          mountPath: /mnt/data
  volumes:
    - name: my-volume
      persistentVolumeClaim:
        claimName: oci-bv-pvc
```
---
### Block Volume - Raw Block Device Mode (RBV)

Specify `volumeMode: Block` in your PVC and use `volumeDevice` instead of `volumeMounts` when attaching the storage to a Pod.

**PersistentVolumeClaim**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oci-bv-pvc-block
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  volumeMode: Block
```
**Pod**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
    - name: my-container
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeDevices:
        - name: my-volume
          devicePath: /dev/block
  volumes:
    - name: my-volume
      persistentVolumeClaim:
        claimName: oci-bv-pvc-rbv
```
---
### Block Volume - ReadWriteMany (RWX) RBV
**PersistentVolumeClaim**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: oci-bv-pvc-rwx
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  volumeMode: Block
  ```
**Deployment (attaching volumes to multiple instances)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deploy
  labels:
    app: my-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-deploy
  template:
    metadata:
      labels:
        app: my-deploy
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: my-deploy
      containers:
      - name: my-container
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
        volumeDevices:
        - name: my-volume
          devicePath: /dev/block
      volumes:
      - name: my-volume
        persistentVolumeClaim:
          claimName: oci-bv-pvc-rwx
```
