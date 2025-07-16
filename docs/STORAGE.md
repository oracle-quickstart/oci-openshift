# Cloud Storage for OpenShift Clusters on OCI

## Overview

To deliver an optimized and performant persistent storage solution for OpenShift clusters on Oracle Cloud Infrastructure (OCI), we provide manifests to deploy the OCI Container Storage Interface (CSI) driver to your OpenShift cluster. In collaboration with the Oracle Kubernetes Engine (OKE) team, who own and maintain the open source [oci-cloud-controller-manager](https://github.com/oracle/oci-cloud-controller-manager) repository, we have adapted the drivers for OpenShift on OCI (OSO), and we are continuing to add new features and enhancements for users of both OKE and OSO.

The default storage option for the OCI CSI driver is the [OCI Block Volume Service](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/overview.htm).


### Available Feature Matrix


| Category                 | Options                    | Mode: `Filesystem` | Mode: `Block` |
|------------------------------|------------------------------|----------------------|----------------------------|
| **Lifecycle Management**     | Creation & Deletion of Volumes | ✅ | ✅ |
|                              | Volume Expansion               | ✅                   | ✅                         |
| **Volume Attachment Types**  | iSCSI                          | ✅                   | ✅                         |
|                              | Paravirtualized                | ✅                   | ✅                         |
| **[Performance Tiers](https://docs.oracle.com/en-us/iaas/Content/Block/Concepts/blockvolumeperformance.htm)** (vpusPerGB)       | Ultra High Performance (30+)        | ✅                   | ✅ |
|                              | Higher Performance (20)             | ✅                   | ✅  |
|                              | Balanced (10) - default                  | ✅                  | ✅ |
|                              | Lower Cost (0)                 | ✅                   | ✅                         |
| **Storage Features**         | Snapshotting                   | ✅                   | ✅                         |
|                              | Encryption                     | ✅                   | ✅                         |
|                              | Cloning                        | ✅                   | ✅                         |
| **[Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)**          | ReadWriteOnce | ✅ |✅ |
| | ReadOnlyMany | ❌ | ✅ |
| | ReadyWriteMany | ❌ | ✅ |
| | | |

### Limitations and Considerations

1. The maximum number of different instances a Block Volume can be attached to is **32**.
2. The maximum number of Block Volume attachments a single instance can have is **32**.
3. Block Volumes have an Availability Domain (AD) and can only be attached to instances within the same AD.
4. A Block Volume's performance (vpusPerGB) is shared between all attachments.
5. The OCI CSI driver can provision, attach, and mount Block Volumes to instances - it **can't** manage read/write events between workloads and the underlying storage. To manage concurrent access and ensure data integrity, users must rely on tools and software that are designed to handle this storage setup correctly.


### CSI Driver Components

The [manifests](https://github.com/oracle-quickstart/oci-openshift/tree/main/custom_manifests/manifests) for the OCI CSI driver include the following components:

| **Component**           | **Description**              |**Notes**                           |
|-------------------------|------------------------------|------------------------------------|
| **namespace**           | Defines the `oci-csi` Namespace with specific security and labeling configurations.                | Essential for isolating resources.             |
| **provider config**            | Creates a Secret for OCI volume provisioning configuration, including instance principals and rate limits. | ❗ Requires cluster specific configuration before use           |
| **controller-driver**   | Deployment for the the CSI controller driver with multiple containers for volume provisioning, attachment, resizing, and snapshotting. | Includes multiple containers for different functions. |
| **fss-driver** / **bv-driver**        | Defines the CSIDriver for the File Storage Service (FSS) & Block Volume in OCI.| Handles file storage operations.               |
| **iscsiadm** / **fss-csi** | ConfigMap with a script for managing `iscsiadm` operations, FSS mounts, and unmounts.| Configures necessary scripts for storage management. |
| **node-driver**         | DaemonSet that deploys the CSI node driver on worker nodes | Ensures CSI driver is running on each worker node.|
| **RBAC rules**        | Creates a ServiceAccount / ClusterRole / ClusterRoleBinding for driver components.| Provides necessary permissions for the CSI driver. |
| **storage-classes**    | Defines StorageClasses for volumes with specified provisioning parameters.                    | Optional      |

## Installation / Setup

### Prerequisites

The `oci-volume-provisioner` Secret in [01-oci-driver-configs.yml](https://github.com/oracle-quickstart/oci-openshift/blob/main/custom_manifests/manifests/01-oci-driver-configs.yml) contains placeholder values and must be configured for each cluster. If using our Terraform to provision cluster resources, the `dynamic_custom_manifest` output includes this Secret, pre-formatted with the resource OCIDs for your cluster. If you are manually provisioning OCI resources, you must update the Secret with the necessary values yourself. View provider config examples [here](https://github.com/oracle/oci-cloud-controller-manager/blob/master/manifests/provider-config-instance-principals-example.yaml).

To allow the CSI driver to operate on the OCI resources for your cluster, IAM Policies must be created in your tenancy which give access to a Dynamic Group comprised of the instances on which the CSI components are deployed. If you are using our Terraform to provision resources, the necessary [Dynamic Groups](https://github.com/oracle-quickstart/oci-openshift/blob/main/terraform-stacks/shared_modules/iam/dynamic_group.tf) and [Policies](https://github.com/oracle-quickstart/oci-openshift/blob/main/terraform-stacks/shared_modules/iam/policy.tf) are created for you.

Read more about these OCI IAM resources below:
- [IAM Policies](https://docs.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm)
- [Dynamic Groups](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/callingservicesfrominstances.htm)
- [Block Volume Policies](https://docs.oracle.com/en-us/iaas/Content/Block/blockvolumes.htm#blockvolumes__iam)
- [File System Policies](https://docs.oracle.com/en-us/iaas/Content/File/Concepts/filestorageoverview.htm#auth)
- [Keys and Vault Policies](https://docs.oracle.com/en-us/iaas/Content/KeyManagement/Concepts/keyoverview.htm#authentication)

### Deployment

The manifests for the OCI CSI driver are typically deployed to an OpenShift cluster via [custom_manifests](https://github.com/oracle-quickstart/oci-openshift/tree/main/custom_manifests) produced by Terraform and applied during installation.

Set the oci_driver_version variable when creating a cluster using the create-cluster Terraform stack to generate the dynamic_custom_manifest output with the specified driver version. By default, the latest GA version is used.

#### To upgrade/change OCI CSI driver on an existing OpenShift cluster

1. Find the version of the oci-ccm-csi-driver [manifests](https://github.com/oracle-quickstart/oci-openshift/tree/main/custom_manifests/oci-ccm-csi-drivers) you need.
2. Apply the changes manually or with the following command:

```bash
oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-ccm.yml
oc apply -f custom_manifests/oci-ccm-csi-drivers/${OCI_DRIVER_VERSION}/01-oci-csi.yml
```

## Examples

### Block Volumes - Filesystem Mode

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

**Pod**
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

### Block Volumes - Raw Block Device Mode

Use `volumeMode: Block` and use `volumeDevice` instead of `volumeMounts`

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
  volumeMode: Block
  ```

**Pod**

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
      volumeDevices:
        - name: my-volume
          devicePath: /dev/block
  volumes:
    - name: my-volume
      persistentVolumeClaim:
        claimName: my-pvc-rbv

  ```

### Block Volumes - ReadWriteMany

**PersistentVolumeClaim (PVC)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-rwx
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  volumeMode: Block
  ```

**Distributed Workload Deployment**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deploy-rwx
  labels:
    app: my-deploy-rwx
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-deploy-rwx
  template:
    metadata:
      labels:
        app: my-deploy-rwx
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: my-deploy-rwx
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
          claimName: my-pvc-rwx
  ```
