#!/bin/bash

## Install webserver and tar
sudo dnf -y install httpd tar
sudo systemctl enable --now httpd.service
sudo firewall-cmd --add-service=http --permanent
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
sudo setenforce 0

## Inject template variables
set_proxy=${set_proxy}
http_proxy=${http_proxy}
https_proxy=${https_proxy}
no_proxy=${no_proxy}
openshift_installer_version=${openshift_installer_version}
agent_install_dir=${agent_install_dir}
object_storage_bucket=${object_storage_bucket}
object_storage_namespace=${object_storage_namespace}
dynamic_custom_manifest_object=${dynamic_custom_manifest_object}
agent_config_object=${agent_config_object}
install_config_object=${install_config_object}
cluster_name=${cluster_name}

# only needed when there isn't public internet access
# if cluster is only accessible from jumphost/webserver, append {cluster_name}.{baseDomain} to `no_proxy` e.g. `df-test.disconnected.dfosterdev.com`
if [ "$set_proxy" = "true" ]; then
export http_proxy="${http_proxy}"
export https_proxy="${https_proxy}"
export no_proxy="${no_proxy}"
echo "Proxy environment variables set."
else
echo "Proxy environment variables not set."
fi

## Download and Install OpenShift Install and OC client
wget -nv https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${openshift_installer_version}/openshift-install-linux.tar.gz
tar -xf openshift-install-linux.tar.gz
sudo mv openshift-install /usr/local/bin/.

wget -nv https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xf openshift-client-linux.tar.gz
sudo mv oc /usr/local/bin/.

sudo dnf -y install oraclelinux-developer-release-el9
sudo dnf -y install python39-oci-cli

# Prepare OpenShift agent-based deployment directory
mkdir -p "${agent_install_dir}/openshift"
sudo chmod -R a+w ${agent_install_dir}

echo "Fetching OpenShift agent install artifacts from OCI Object Storage..."

# maybe put this in a loop that can retry
oci --auth instance_principal os object get --bucket-name "${object_storage_bucket}" --namespace "${object_storage_namespace}" --name "${agent_config_object}" --file "${agent_install_dir}/agent-config.yaml"
oci --auth instance_principal os object get --bucket-name "${object_storage_bucket}" --namespace "${object_storage_namespace}" --name "${install_config_object}" --file "${agent_install_dir}/install-config.yaml"
oci --auth instance_principal os object get --bucket-name "${object_storage_bucket}" --namespace "${object_storage_namespace}" --name "${dynamic_custom_manifest_object}" --file "${agent_install_dir}/openshift/dynamic-custom-manifest.yaml"

echo "Backing up Agent-based OpenShift artifacts:"
cp -R "${agent_install_dir}" "${agent_install_dir}-backup"

echo "Agent-based OpenShift artifacts written:"
ls -l "${agent_install_dir}"
ls -l "${agent_install_dir}/openshift"


echo "Webserver setup script completed."
