# Disconnected Bastion Setup — Agent ISO to OCI Custom Image

When deploying OpenShift on OCI in a disconnected (air-gapped) environment with
FIPS enabled, the `openshift-install-fips` command must run from a FIPS-enabled
RHEL 9 server. This guide describes how to use the bastion (where Terraform
runs) to generate the agent ISO and import it as an OCI custom image.

## Boot flow

VMs in OCI cannot PXE boot. Instead, the agent-based installer workflow on OCI
is a two-pass Terraform apply with a manual ISO creation step in between:

1. **First `terraform apply`** with `create_openshift_instances = false`
   - Creates networking, DNS, load balancers, tags, IAM
   - Generates `agent-config.yaml`, `install-config.yaml`, and custom manifests
     as Terraform outputs
   - Uploads manifests to OCI Object Storage as a backup

2. **Create the agent ISO** on the bastion (between the two applies)
   - Write the Terraform outputs to disk
   - Run `openshift-install-fips agent create image` to produce `agent.x86_64.iso`
   - Upload the ISO to OCI Object Storage
   - Create a Pre-Authenticated Request (PAR) URL for the ISO

3. **Second `terraform apply`** with `create_openshift_instances = true`
   - Set `openshift_image_source_uri` to the PAR URL of the agent ISO
   - OCI imports the ISO as a custom image (UEFI boot, QCOW2 type)
   - Compute instances boot from this custom image
   - The agent installer embedded in the ISO orchestrates the cluster install

All configuration (install-config, agent-config, custom manifests) is baked into
the ISO. No httpd, no rootfs serving, no `bootArtifactsBaseURL` needed.

## Terraform configuration

Set the following in your tfvars:

```hcl
is_disconnected_installation = true
create_webserver_instance    = false
enable_fips                  = true
create_openshift_instances   = false   # first pass
```

After creating the ISO and uploading it, update for the second pass:

```hcl
create_openshift_instances   = true
openshift_image_source_uri   = "<PAR URL to agent.x86_64.iso>"
```

## Bastion prerequisites

### Packages

| Package | Purpose |
|---------|---------|
| `tar` | Extract OpenShift client and installer tarballs |

### Binaries (pre-staged from a connected host or mirror)

| Binary | Purpose |
|--------|---------|
| `openshift-install-fips` | Agent-based installer (FIPS build for RHEL 9) |
| `oc` | OpenShift CLI |

For FIPS-enabled deployments, use the RHEL 9 FIPS-specific installer binary
from the OpenShift mirror or your disconnected mirror registry.

### System requirements

| Requirement | How to verify |
|-------------|---------------|
| FIPS mode enabled | `fips-mode-setup --check` → "FIPS mode is enabled." |
| SELinux enforcing | `getenforce` → "Enforcing" |
| Terraform installed | `terraform version` |

## Complete bastion workflow

```bash
# 1. Install packages
sudo dnf -y install tar

# 2. Pre-stage OpenShift binaries (copied from a connected host or mirror)
sudo cp openshift-install-fips /usr/local/bin/
sudo cp oc /usr/local/bin/
sudo chmod +x /usr/local/bin/openshift-install-fips /usr/local/bin/oc

# 3. Verify FIPS mode
fips-mode-setup --check
# Should report: "FIPS mode is enabled."

# 4. First terraform apply (infrastructure only, no instances)
cd oci-openshift-mine/terraform-stacks/create-cluster
terraform init
terraform apply -var-file=../../openshift-on-oci.tfvars

# 5. Capture Terraform outputs
mkdir -p ~/<cluster>-agentBasedInstallation/openshift
terraform output -raw agent_config    > ~/<cluster>-agentBasedInstallation/agent-config.yaml
terraform output -raw install_config  > ~/<cluster>-agentBasedInstallation/install-config.yaml
terraform output -raw dynamic_custom_manifest > ~/<cluster>-agentBasedInstallation/openshift/dynamic-custom-manifest.yaml

# 6. Backup
cp -R ~/<cluster>-agentBasedInstallation ~/<cluster>-agentBasedInstallation-backup

# 7. Create the agent ISO
cd ~/<cluster>-agentBasedInstallation
openshift-install-fips agent create image

# 8. Upload ISO to OCI Object Storage and create a PAR URL
# (use OCI Console or oci-cli)

# 9. Second terraform apply (create instances from the ISO)
# Update tfvars: create_openshift_instances = true
#                openshift_image_source_uri = "<PAR URL>"
cd oci-openshift-mine/terraform-stacks/create-cluster
terraform apply -var-file=../../openshift-on-oci.tfvars

# 10. Monitor installation
openshift-install-fips agent wait-for install-complete \
  --dir ~/<cluster>-agentBasedInstallation
```

## Network requirements

The bastion must have:

- Connectivity to OCI API endpoints for Terraform and Object Storage
- Connectivity to the private OCP subnet (for monitoring the install)
- Its IP allowed through the cluster NSGs if it is on a different subnet
