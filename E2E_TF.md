# End to End CLI

End to end guide to deploying an OpenShift cluster on Oracle Cloud using the Command Line Interface for both oracle CLI and the Red Hat Assisted Installer.

## Expected Variables (.envrc)
```
echo OCI_CLI_REGION=$OCI_CLI_REGION
echo PARENT_COMPARTMENT_ID=$PARENT_COMPARTMENT_ID
echo TENANCY_ID=$TENANCY_ID
echo TENANCY_COMPARTMENT_ID=$TENANCY_COMPARTMENT_ID
echo ZONE_ID=$ZONE_ID

# https://cloud.redhat.com/openshift/token
echo AI_OFFLINETOKEN=$AI_OFFLINETOKEN

# https://console.redhat.com/openshift/install/pull-secret
echo PULL_SECRET=$PULL_SECRET
```

```
echo "ocpoci$RANDOM" > cluster_name.txt
export CLUSTER_NAME=$(cat cluster_name.txt)
echo $CLUSTER_NAME

export SSH_PUBLIC_KEY=$(cat $HOME/.ssh/id_rsa_oci.pub)
echo $SSH_PUBLIC_KEY
```

## Check Oracle CLI 
```
export NAMESPACE=$(oci os ns get | jq -r '.data')
echo $NAMESPACE
```

## Setup and check Assisted Installer CLI
```
export PULL_SECRET
echo $PULL_SECRET | tee openshift_pull.json

ocm login --token="$AI_OFFLINETOKEN"

aicli list cluster
```

## Create Cluster

```
export OCP_VERSION="4.14"

export MANIFESTS_DIR="user-manifests"
export BASE_DOMAIN

mkdir -p "$MANIFESTS_DIR"
```

```
aicli create cluster "$CLUSTER_NAME" -P openshift_version="$OCP_VERSION" -P base_dns_domain="$BASE_DOMAIN" -P platform=oci 
```

## Download installer image
```
aicli download iso "$CLUSTER_NAME"
export IMAGE_FILE="${CLUSTER_NAME}.iso"
```


## Create Compartment (if needed)

```
oci iam compartment create \
    --compartment-id "$PARENT_COMPARTMENT_ID" \
    --name "$CLUSTER_NAME-cptmt" \
    --description "$CLUSTER_NAME-cptmt" | tee compartment.json
export COMPARTMENT_ID=$(jq -r '.data.id' compartment.json)
echo $COMPARTMENT_ID

export COMPARTMENT_NAME=$(jq -r '.data.name' compartment.json)
echo $COMPARTMENT_NAME
```

## Create Bucket (if needed)
```
export IMAGE_BUCKET_NAME="$CLUSTER_NAME"
echo $IMAGE_BUCKET_NAME

export IMAGE_COMPARTMENT_ID="$COMPARTMENT_ID"
echo $IMAGE_COMPARTMENT_ID

oci os bucket create \
    --name "$IMAGE_BUCKET_NAME" \
    --region "$OCI_CLI_REGION" \
    --compartment-id "$IMAGE_COMPARTMENT_ID" | tee bucket-create.json

oci os object put \
    --bucket-name "$IMAGE_BUCKET_NAME" \
    --name "$IMAGE_FILE" \
    --file "$IMAGE_FILE" | tee object-put.json

```

* manually update to desired shapes
* manually change launch options to UEFI (Image Capabilities > Disble BIOS)


## Create Stack
```
pushd tf-oci-standard
zip -j -r ../tf.zip ./*
popd 
unzip -l tf.zip 

export CONFIG_SOURCE="tf.zip"
echo $CONFIG_SOURCE

export ZONE_DNS="$CLUSTER_NAME.$BASE_DOMAIN"
echo $ZONE_DNS

export IMAGE_URI="https://objectstorage.$OCI_CLI_REGION.oraclecloud.com/n/$NAMESPACE/b/$IMAGE_BUCKET_NAME/o/$IMAGE_FILE"
echo $IMAGE_URI

oci resource-manager stack create \
  --compartment-id "$COMPARTMENT_ID" \
  --config-source $CONFIG_SOURCE \
  --display-name "${CLUSTER_NAME}-stack" \
  --description "$CLUSTER_NAME stack" \
  --terraform-version "0.12.x" \
  --variables "{\
        \"home_region\": \"$OCI_CLI_REGION\", \
        \"zone_dns\": \"$ZONE_DNS\", \
        \"master_count\": \"3\", \
        \"master_shape\": \"VM.Standard.E4.Flex\", \
        \"master_ocpu\": \"4\", \
        \"master_memory\": \"32\", \
        \"master_boot_size\": \"500\", \
        \"master_boot_volume_vpus_per_gb\": \"60\", \
        \"worker_count\": \"3\", \
        \"worker_shape\": \"VM.Standard.E4.Flex\", \
        \"worker_ocpu\": \"4\", \
        \"worker_boot_volume_vpus_per_gb\": \"20\", \
        \"worker_memory\": \"16\", \
        \"worker_boot_size\": \"128\", \
        \"tenancy_ocid\": \"$TENANCY_ID\", \
        \"compartment_ocid\": \"$COMPARTMENT_ID\", \
        \"cluster_name\": \"$CLUSTER_NAME\", \
        \"vcn_cidr\": \"10.0.0.0/16\", \
        \"private_cidr\": \"10.0.16.0/20\", \
        \"public_cidr\": \"10.0.0.0/20\", \
        \"openshift_image_source_uri\": \"$IMAGE_URI\" \
        } " | tee create-stack.json

export STACK_ID=$(jq -r '.data.id' create-stack.json)
echo $STACK_ID

oci resource-manager job create-apply-job \
    --stack-id $STACK_ID \
    --execution-plan-strategy=AUTO_APPROVED | tee apply-job.json
export JOB_ID=$(jq -r '.data.id' create-stack.json)
echo $JOB_ID

oci resource-manager job get --job-id $JOB_ID
```


## Update node roles
```
aicli -o json list hosts > all_hosts.json

export WK_HOST_IDS=$(jq -r '.[] | select(.role != "master") | .id' all_hosts.json)
echo $WK_HOST_IDS

for WK_HOST_ID in $WK_HOST_IDS; do
  echo "Updating role of $WK_HOST_ID to control plane"
  aicli update host $WK_HOST_ID -P role=worker
done
```

# Continue Install
```
aicli start "$CLUSTER_NAME"
```


# Verifying compatibility with OPCT

https://github.com/redhat-openshift-ecosystem/provider-certification-tool/blob/main/docs/user.md

```
export OPCT_NODE=$(oc get nodes | tail -1 | cut -d" " -f 1)
echo $OPCT_NODE

oc label node $OPCT_NODE node-role.kubernetes.io/tests=""
oc adm taint node $OPCT_NODE node-role.kubernetes.io/tests="":NoSchedule


VERSION=v0.4.1
BINARY=opct-linux-amd64
wget -O opct "https://github.com/redhat-openshift-ecosystem/provider-certification-tool/releases/download/${VERSION}/${BINARY}"
chmod u+x ./opct

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'


./opct run --watch
```