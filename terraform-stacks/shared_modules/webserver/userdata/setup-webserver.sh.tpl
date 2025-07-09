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

# TODO - make these permanent by writing to /etc/environment. Make use of set_proxy and other proxy related variables.
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

echo "Webserver setup script completed."
