## Technical Preview of RWX Raw Block Volumes for OpenShift on OCI

### Table of Contents

- [Overview](#overview)
- [Available Feature Matrix](#available-feature-matrix)
- [Limitations](#limitations)
- [Driver Installation](#driver-installation)
- [Usage - ReadWriteOnce Raw Block Volume](#usage---readwriteonce-raw-block-volume)
- [Usage - ReadWriteMany Raw Block Volume](#usage---readwritemany-raw-block-volume)


### Overview

We are pleased to inform you that we have further enhanced the OCI CSI driver for OpenShift on OCI. In collaboration with the Oracle Kubernetes Engine (OKE) team, who own and maintain the open source [oci-cloud-controller-manager](https://github.com/oracle/oci-cloud-controller-manager), we have added the capability to create Raw Block Volumes in ReadWriteMany mode and attach them to multiple nodes within the same Availability Domain (see [Limitations](#limitations)). The addition of this capability enables users to distribute workloads that used shared storage accross multiple nodes and take advantage of tools and software that utilize or require ReadWriteMany storage capabilities, such as [OpenShift Virtualization](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/virtualization/index) and the [Migration Toolkit for Virtualization](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/2.7/html/installing_and_using_the_migration_toolkit_for_virtualization/index).

This feature is currently only available as a Technical Preview in Limited Availability, but will be incorporated into a future version of the open source OCI CCM and CSI drivers we use for our OpenShift clusters today.

For more information, please refer to the following documentation:
- [Installing OpenShift Virtualization in OpenShift clusters on OCI]()
- [OCI Container Storage Interface](https://github.com/oracle/oci-cloud-controller-manager/blob/master/container-storage-interface.md)
- [OCI Block Storage](https://docs.oracle.com/en-us/iaas/Content/Block/blockvolumes.htm)
- [Kubernetes Persistant Storage Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)
- [Container Storage Interface Specification](https://github.com/container-storage-interface/spec/blob/master/spec.md)

### Available Feature Matrix

| **Category**                 | **Options**                    | **`volumeMode: Filesystem`** | **`volumeMode: Block`** |
|------------------------------|--------------------------------|----------------------|----------------------------|
| **Lifecycle Management**     | Creation & Deletion of Volumes | ✔️                   | ✔️                         |
|                              | Expansion                      | ✔️                   | ✔️                         |
| **Volume Attachment Types**  | iSCSI                          | ✔️                   | ✔️                         |
|                              | Paravirtualized                | ✔️                   | ✔️                         |
| **Performance Tiers - vpusPerGB**        | Ultra High Performance - 30+        | ✔️                   | Not Available             |
|                              | Higher Performance - 20             | ✔️                   | ✔️                         |
|                              | Balanced (Default)  - 10                     | ✔️                   | ✔️                         |
|                              | Lower Cost - 0                 | ✔️                   | ✔️                         |
| **Storage Features**         | Snapshotting                   | ✔️                   | ✔️                         |
|                              | Encryption                     | ✔️                   | ✔️                         |
|                              | Cloning                        | ✔️                   | ✔️                         |
| **[Access Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)**          | ReadWriteOnce | ✔️ |✔️ |
| | ReadOnlyMany | Not Available | ✔️ |
| | ReadyWriteMany | Not Available | ✔️ |
| | | |


### Limitations

These RWX-enabled drivers are being made available as a Technical Preview in Limited Availability. While these drivers have been extensively tested by both our team and RedHat's, they have not been fully certified. Please be considerate of that when you choose what environments to test these in.

Be aware that the following limitations apply when using ReadWriteMany Raw Block Volumes:

1. ReadWriteMany accessMode is only available for Raw Block Volumes i.e. `volumeMode: Block`
2. The maximum number of different instances a volume can be attached to is **32**
3. Block Volumes can only be attached to instances within the same Availability Domain.
4. A Block Volume's performance (vpusPerGB) is shared between all of it's attachments.
5. The CSI driver can provision, attach, and mount Block Volumes to instances - it **can't** control read/write events between workloads and the underlying storage. To manage concurrent access and data integrity, users must rely on tools and software that are designed to handle this storage setup correctly.

### Driver Installation

The RWX-enabled OCI CSI driver manifests can be found in [01-oci-csi.yml](01-oci-csi.yml), and can be used to upgrade the OCI CSI driver on an existing OpenShift cluster. Apply the manifests manually or with the following command:

```bash
export KUBECONFIG=<your_cluster_kubeconfig>

make update-drivers OCI_DRIVER_VERSION=v1.30.0-RWX-LA
```

### Usage - ReadWriteOnce Raw Block Volume

**PersistentVolumeClaim (PVC)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-rwo
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 55Gi
  storageClassName: oci-bv
  volumeMode: Block
  ```

**Pod Creation**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod-rwo
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
        claimName: my-pvc-rwo
  ```
### Usage - ReadWriteMany Raw Block Volume

**PersistentVolumeClaim (PVC)**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc-rwx
spec:
  accessModes:
    - ReadWriteMany                        <--------- New accessMode
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
