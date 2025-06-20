# OpenShift on OCI (OSO)

This repository contains [Terraform stacks](/terraform-stacks/README.md) as well as OpenShift and Kubernetes [manifest files](/custom_manifests/README.md) to support the deployment, installation, and management of Red Hat OpenShift clusters on Oracle Cloud Infrastructure (OCI).

## Prerequisites
⚠️ Important: Before creating the cluster, ensure you've executed the latest version of create-attribution-tags stack. This ensures all necessary tags are available prior to cluster provisioning.
You only need to run this for the `first cluster deployment`. Subsequent cluster deployments will not require this step, as the tags will already exist.

## Documentation and Installation Instructions

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
