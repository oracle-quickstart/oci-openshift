# Disconnected Bastion Setup — Combined Bastion + Webserver

When deploying OpenShift on OCI in a disconnected (air-gapped) environment with
FIPS enabled, the `openshift-install` command must run from a FIPS-enabled
RHEL 9 server. This guide describes how to collapse the Terraform-managed
webserver VM and the bastion (where Terraform runs) into a single RHEL 9 host.

## Terraform configuration

Set the following in your tfvars to use the bastion as the webserver:

```hcl
is_disconnected_installation = true
create_webserver_instance    = false
webserver_private_ip         = "10.40.0.20"  # bastion's private IP
```

This keeps `is_disconnected_installation = true` so that:

- `bootArtifactsBaseURL` is set in `agent-config.yaml` (pointing at the
  bastion's httpd)
- The three install manifests are uploaded to OCI Object Storage as a backup
- Proxy settings and other disconnected fields remain available

But skips creation of the webserver VM (`create_webserver_instance = false`).

The manifests are also available as Terraform outputs — write them directly
to disk after `terraform apply` instead of pulling from Object Storage:

```bash
terraform output -raw agent_config    > ~/<cluster>-agentBasedInstallation/agent-config.yaml
terraform output -raw install_config  > ~/<cluster>-agentBasedInstallation/install-config.yaml
terraform output -raw dynamic_custom_manifest > ~/<cluster>-agentBasedInstallation/openshift/dynamic-custom-manifest.yaml
```

## What the webserver setup script installs

The cloud-init script (`setup-webserver.sh.tpl`) installs the following on
the webserver VM. On a combined bastion these must be pre-staged before
running Terraform.

### Packages (via dnf)

| Package | Purpose |
|---------|---------|
| `httpd` | Apache HTTP server — serves boot artifacts to cluster nodes |
| `tar` | Extract OpenShift client and installer tarballs |

The upstream script also installs `oraclelinux-developer-release-el9` and
`python39-oci-cli`, which are Oracle Linux packages. On RHEL 9, install the
OCI CLI via `pip install oci-cli` or the
[Oracle install script](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)
if you need it. On the bastion you authenticate with an API key or session
token rather than instance principal.

### Binaries (downloaded from mirror.openshift.com)

These are fetched via `wget` from `mirror.openshift.com`, which is
unreachable in an air-gapped environment. Pre-stage them on the bastion.

| Binary | Source tarball | Install location |
|--------|--------------|------------------|
| `openshift-install` | `openshift-install-linux.tar.gz` (or `openshift-install-rhel9-amd64.tar.gz` for FIPS) | `/usr/local/bin/openshift-install` |
| `oc` | `openshift-client-linux.tar.gz` | `/usr/local/bin/oc` |

For FIPS-enabled deployments, use the RHEL 9 FIPS-specific installer binary
(`openshift-install-rhel9`) from the OpenShift mirror or your disconnected
mirror registry.

### Firewall and services

| Configuration | Command | Notes |
|--------------|---------|-------|
| Enable httpd | `systemctl enable --now httpd.service` | Must survive reboot |
| Open HTTP port | `firewall-cmd --add-service=http --permanent` | Required for cluster nodes to reach boot artifacts |
| Open port 80 | `firewall-cmd --add-port=80/tcp --permanent` | Redundant with the above but present in the upstream script |
| Reload firewall | `firewall-cmd --reload` | |
| SELinux permissive | `setenforce 0` | The upstream script disables SELinux enforcement. On RHEL with FIPS you may prefer to keep enforcing and use `setsebool -P httpd_read_user_content 1` instead |

### Directory structure

The setup script creates the following directory tree (where `<cluster>` is
the value of `cluster_name`, e.g. `ocp-deployment`):

```
/home/cloud-user/<cluster>-agentBasedInstallation/
├── agent-config.yaml
├── install-config.yaml
└── openshift/
    └── dynamic-custom-manifest.yaml

/home/cloud-user/<cluster>-agentBasedInstallation-backup/
└── (copy of the above)
```

## Network requirements

The bastion must have:

- Connectivity to the **private OCP subnet** (where cluster nodes live) on
  port 80, so nodes can reach httpd for boot artifacts
- Connectivity to OCI API endpoints for Terraform and Object Storage
- Its IP allowed through the cluster NSGs if it is on a different subnet
  than the webserver would have been (the webserver is normally placed on
  the public subnet)

## Complete bastion setup checklist

```bash
# 1. Install packages
sudo dnf -y install httpd tar

# 2. Enable and configure httpd
sudo systemctl enable --now httpd.service
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --reload

# 3. Pre-stage OpenShift binaries (copied from a connected host or mirror)
sudo cp openshift-install /usr/local/bin/
sudo cp oc /usr/local/bin/
sudo chmod +x /usr/local/bin/openshift-install /usr/local/bin/oc

# 4. (Optional) Install OCI CLI
pip install oci-cli

# 5. Verify FIPS mode
fips-mode-setup --check
# Should report: "FIPS mode is enabled."

# 6. Create install directory
mkdir -p ~/<cluster>-agentBasedInstallation/openshift

# 7. Run terraform apply, then capture outputs
terraform output -raw agent_config    > ~/<cluster>-agentBasedInstallation/agent-config.yaml
terraform output -raw install_config  > ~/<cluster>-agentBasedInstallation/install-config.yaml
terraform output -raw dynamic_custom_manifest > ~/<cluster>-agentBasedInstallation/openshift/dynamic-custom-manifest.yaml

# 8. Backup
cp -R ~/<cluster>-agentBasedInstallation ~/<cluster>-agentBasedInstallation-backup

# 9. Run agent-based installer
cd ~/<cluster>-agentBasedInstallation
openshift-install agent create image
openshift-install agent wait-for install-complete
```
