# Command Line Interface Guide

Guide for creating an openshift cluster on OCI using preferably the command line interface.

# Configure Variables 

```
# Oracle Config
# https://cloud.oracle.com
export OCI_CLI_REGION="us-sanjose-1"
echo $OCI_CLI_REGION

# https://cloud.oracle.com/identity/compartment
# https://cloud.oracle.com/tenancy
#  TENANCY_ID=
export TENANCY_ID
echo $TENANCY_ID

export NAMESPACE=$(oci os ns get | jq -r '.data')
echo $NAMESPACE

# Red Hat Config
# https://console.redhat.com/openshift/token/show
export AI_OFFLINETOKEN
echo $AI_OFFLINETOKEN

export PULL_SECRET
echo $PULL_SECRET | tee openshift_pull.json

export CLUSTER_NAME="ocpoci$RANDOM"
export BASE_DOMAIN="splat-oci.devcluster.openshift.com"
export MANIFESTS_DIR="user-manifests"

```

# Prepare the OCI account

## Create Compartment (if needed)

```
oci iam compartment create \
    --compartment-id "$PARENT_COMPARTMENT_ID" \
    --name "$CLUSTER_NAME-cptmt" \
    --description "$CLUSTER_NAME-cptmt" | tee compartment.json
export COMPARTMENT_ID=$(jq -r '.data.id' compartment.json)
echo $COMPARTMENT_ID
```


# Create Bucket

```
export IMAGE_BUCKET_NAME="$CLUSTER_NAME"

oci os bucket create \
    --name "$IMAGE_BUCKET_NAME" 
```

# Create a cluster using the Assisted Installer


## Create Cluster
```
aicli create cluster "$CLUSTER_NAME" -P openshift_version="4.14" -P base_dns_domain="$BASE_DOMAIN" -P manifests="$MANIFESTS_DIR"
```

## Download installer image
```
aicli download iso "$CLUSTER_NAME"
export IMAGE_FILE="${CLUSTER_NAME}.iso"
```

# Create OCI Resources

## Upload Image to Oracle CLI
```
oci os object put \
    --bucket-name "$IMAGE_BUCKET_NAME" \
    --name "$IMAGE_FILE" \
    --file "$IMAGE_FILE" | tee object-put.json
```

## Import the Image
```
export IMAGE_LAUNCH_MODE="PARAVIRTUALIZED"
oci compute image import from-object 
    --namespace "$NAMESPACE" \
    --name "$IMAGE_FILE" \
    --launch-mode "$IMAGE_LAUNCH_MODE" \
    --display-name "$CLUSTER_NAME"| tee image-import.json

export CUSTOM_IMAGE_ID=$(jq -r '.data.id' image-import.json)
echo $CUSTOM_IMAGE_ID

export IMAGE_URL="https://cloud.oracle.com/compute/images/$CUSTOM_IMAGE_ID?region=$OCI_CLI_REGION"
echo $IMAGE_URL
```

# Enable Image for Shapes

Manually on OCP console (Custom Image Details > Edit Details)

# Set the image for UEFI_64 boot

Manually on OCP console (Custom Image Details > Edit Details)


# Continue with the installation

# Set TF variables
```
export TF_VAR_region="$OCI_CLI_REGION"
export TF_VAR_zone_dns="$CLUSTER_NAME.$BASE_DOMAIN"
export TF_VAR_openshift_image_id="$CUSTOM_IMAGE_ID"
export TF_VAR_tenancy_ocid="$TENANCY_ID"
export TF_VAR_master_count="3"
export TF_VAR_master_shape="VM.Standard.E4.Flex"
export TF_VAR_master_ocpu="4"
export TF_VAR_master_memory="16"
export TF_VAR_master_boot_size="128"
export TF_VAR_master_boot_volume_vpus_per_gb="24"
export TF_VAR_worker_count="3"
export TF_VAR_worker_shape="VM.Standard.E4.Flex"
export TF_VAR_worker_ocpu="2"
export TF_VAR_worker_boot_volume_vpus_per_gb="16"
export TF_VAR_worker_memory="16"
export TF_VAR_worker_boot_size="128"
export TF_VAR_cluster_name="$CLUSTER_NAME"
export TF_VAR_vcn_cidr="10.0.0.0/16"
export TF_VAR_private_cidr="10.0.16.0/20"
export TF_VAR_public_cidr="10.0.0.0/20"
export TF_VAR_image_bucket_name="$IMAGE_BUCKET_NAME"
export TF_VAR_image_name="${CLUSTER_NAME}.iso"
export TF_VAR_image_bucket_namespace="$NAMESPACE"
export TF_VAR_compartment="$COMPARTMENT_ID"
```

## Initialize TF
```
terraform init
```

## Apply TF
```
terraform apply -auto-approve
```

## Get TF outputs
```
export OCP_VCN_ID=$(tf output -raw vcn_id)
echo $OCP_VCN_ID


export OCP_SUBNET_ID=$(tf output -raw  public_subnet_id)
echo $OCP_SUBNET_ID
```

# Continue Assisted Installer

## Generate custom manifests
```
rm -rf "$MANIFESTS_DIR"
mkdir -p "$MANIFESTS_DIR"
mkdir -p "$MANIFESTS_DIR/manifests"
mkdir -p "$MANIFESTS_DIR/openshift"


envsubst < ./oci-manifests/ccm/manifests/oci-ccm.yml > "$MANIFESTS_DIR/manifests/oci-ccm.yml"
envsubst < ./oci-manifests/ccm/openshift/machineconfig-ccm.yml > "$MANIFESTS_DIR/openshift/machineconfig-ccm.yml"
envsubst < ./oci-manifests/csi/manifests/oci-csi.yml > "$MANIFESTS_DIR/manifests/oci-csi.yml"
envsubst < ./oci-manifests/csi/openshift/machineconfig-csi.yml > "$MANIFESTS_DIR/openshift/machineconfig-csi.yml"
```

# Set Instance Roles

<!-- to be continued -->
```

```
