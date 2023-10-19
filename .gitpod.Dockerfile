# docker build --no-cache --progress=plain -f .gitpod.Dockerfile .
FROM gitpod/workspace-full

USER gitpod

# System
RUN bash -c "sudo apt-get update"
RUN bash -c "pip install --upgrade pip"
RUN bash -c "sudo install-packages gettext"

# OpenShift Installer
RUN bash -c "mkdir -p '/tmp/openshift-installer' \
    && wget -nv -O '/tmp/openshift-installer/openshift-install-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-install-linux.tar.gz' \
    && tar zxvf '/tmp/openshift-installer/openshift-install-linux.tar.gz' -C '/tmp/openshift-installer' \
    && sudo mv  '/tmp/openshift-installer/openshift-install' '/usr/local/bin/' \
    && rm '/tmp/openshift-installer/openshift-install-linux.tar.gz'\
    "
    
# Credentials Operator CLI
RUN bash -c "mkdir -p '/tmp/ccoctl' \
    && wget -nv -O '/tmp/ccoctl/ccoctl-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/ccoctl-linux.tar.gz' \
    && tar zxvf '/tmp/ccoctl/ccoctl-linux.tar.gz' -C '/tmp/ccoctl' \
    && sudo mv '/tmp/ccoctl/ccoctl' '/usr/local/bin/' \
    && rm '/tmp/ccoctl/ccoctl-linux.tar.gz'\
    "

# OpenShift CLI
RUN bash -c "mkdir -p '/tmp/oc' \
    && wget -nv -O '/tmp/oc/openshift-client-linux.tar.gz' 'https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/openshift-client-linux.tar.gz' \
    && tar zxvf '/tmp/oc/openshift-client-linux.tar.gz' -C '/tmp/oc' \
    && sudo mv '/tmp/oc/oc' '/usr/local/bin/' \
    && sudo mv '/tmp/oc/kubectl' '/usr/local/bin/' \
    && rm '/tmp/oc/openshift-client-linux.tar.gz' \
    "

# Assited Installer CLI
RUN bash -c "pip install aicli"

# AWS CLIs
RUN bash -c "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip \
    && sudo ./aws/install \
    && aws --version \
    "

# OCI CLI
RUN bash -c "brew install oci-cli"

# Terraform
RUN bash -c "brew install terraform"

# Done :)
RUN bash -c "echo 'done.'"

