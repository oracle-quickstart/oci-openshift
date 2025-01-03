## Storage for OpenShift Clusters on OCI

### Table of Contents

- [Overview](#overview)
- [Available Feature Matrix](#available-feature-matrix)
- [Scope](#scope)
- [Driver Installation](#driver-installation)
- [Pre-requisites](#pre-requisites)
- [Usage - File System Mode](#usage---file-system-mode)
- [Usage - Raw Block Volume Mode](#usage---raw-block-volume-mode)


### Overview

We are excited to introduce significant enhancements to the Container Storage Interface (CSI) drivers for OpenShift Clusters on Oracle Cloud Infrastructure (OCI). These improvements are designed to optimize storage management and deliver better performance for your OpenShift environments.

### Available Feature Matrix

| **Category**                 | **Options**                    | **File Volume Mode** | **Block Volume Mode (LA)** |
|------------------------------|--------------------------------|----------------------|----------------------------|
| **Lifecycle Management**     | Creation & Deletion of Volumes | ✔️                   | ✔️                         |
|                              | Expansion                      | ✔️                   | ✔️                         |
| **Volume Attachment Types**  | iSCSI                          | ✔️                   | ✔️                         |
|                              | Paravirtualized                | ✔️                   | ✔️                         |
| **Performance Tiers**        | Ultra High Performance         | ✔️                   | Not Available             |
|                              | Higher Performance             | ✔️                   | ✔️                         |
|                              | Balanced                       | ✔️                   | ✔️                         |
|                              | Lower Cost                     | ✔️                   | ✔️                         |
| **Storage Features**         | Snapshotting                   | ✔️                   | ✔️                         |
|                              | Encryption                     | ✔️                   | ✔️                         |
|                              | Cloning                        | ✔️                   | ✔️                         |


### Driver Installation

After OCI cluster resource creation and during OpenShift installation, the [CSI driver manifest](/custom_manifests/manifests/01-oci-csi.yml) containing the Kubernetes/OpenShift resource definitions is applied. See the full [installation instructions](/README.md#documentation-and-installation-instructions). 

For updating drivers on existing clusters, see [oci-ccm-csi-drivers](/custom_manifests/README.md#oci-ccm-csi-drivers).

The manifest contains the following components:

| **Component**           | **Description**                                                                                     | **Notes**                                      |
|-------------------------|-----------------------------------------------------------------------------------------------------|------------------------------------------------|
| **namespace**           | Defines the `oci-csi` namespace with specific security and labeling configurations.                | Essential for isolating resources.             |
| **config**              | Creates a secret for OCI volume provisioning configuration, including instance principals and rate limits. | Requires compartment and subnet IDs from the cluster setup           |
| **controller-driver**   | Deploys the CSI controller driver with various components for volume provisioning, attachment, resizing, and snapshotting. | Includes multiple containers for different functions. |
| **fss-driver** / **bv-driver**        | Defines the CSIDriver for the File Storage Service (FSS) & Block Volume in OCI.| Handles file storage operations.               |
| **iscsiadm** / **fss-csi** | ConfigMap with a script for managing `iscsiadm` operations, FSS mounts, and unmounts.| Configures necessary scripts for storage management. |
| **node-driver**         | DaemonSet that deploys the CSI node driver on worker nodes | Ensures CSI driver is running on each node.|
| **rbac rules**        | Creates a ServiceAccount / ClusterRole / ClusterRoleBinding for driver components.| Provides necessary permissions for the CSI driver. |
| **storage-classes**    | Defines StorageClasses for volumes with specified provisioning parameters.                    | Optional      |

## Pre-requisites

| **Category**        | **Documentation**|
|---------------------|----------------------------------------------------------------------------------------|
| **Block Volumes**   | [Block Volume Policies](https://docs.oracle.com/en-us/iaas/Content/Block/blockvolumes.htm#blockvolumes__iam) |
| **File Systems**    | [File Systems Policies](https://docs.oracle.com/en-us/iaas/Content/File/Concepts/filestorageoverview.htm#auth) |
| **Keys and Vault**  | [Keys and Vault Policies](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm#authentication) |

### Usage - File System Mode

**PersistentVolumeClaim (PVC)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-bv
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  ```

**Pod Creation**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-bv
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
        claimName: my-pvc-bv

  ```

For more information, please refer to the documentation at [OCI Container Storage Interface Documentation](https://github.com/oracle/oci-cloud-controller-manager/blob/master/container-storage-interface.md).

### Usage - Raw Block Volume Mode

**PersistentVolumeClaim (PVC)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-rbv
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  volumeMode: Block                        <--------- New Volume Mode
  ```

**Pod Creation**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-rbv
spec:
  containers:
    - name: my-container
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeDevices:                         <--------- Usage of volumeDevice instead of volumeMounts
        - name: my-volume
          devicePath: /dev/block
  volumes:
    - name: my-volume
      persistentVolumeClaim:
        claimName: my-pvc-rbv

  ```
