# Bring Your Own Network (BYON) - OpenShift on OCI

This guide helps you prepare your existing Oracle Cloud Infrastructure (OCI) network for OpenShift deployment using the **Bring Your Own Network (BYON)** approach. Instead of creating new network resources, you can leverage your existing OCI network infrastructure while ensuring it meets all OpenShift requirements.

## What is BYON?

**Bring Your Own Network (BYON)** allows you to use your existing OCI network infrastructure for OpenShift deployment. This approach is ideal when you:

- Already have established network infrastructure in OCI
- Need to integrate OpenShift with existing enterprise networks
- **Previously used the `create-cluster` Terraform stack** to deploy OpenShift and want to reuse the same network infrastructure for additional clusters

## Common BYON Scenarios

### **Reusing Network from Previous OpenShift Deployments**

If you previously deployed OpenShift on OCI using the **`create-cluster` Terraform stack**, you already have a complete network infrastructure that meets all OpenShift requirements. The `create-cluster` stack creates:

- VCN with proper CIDR configuration
- All required gateways (Internet, NAT, Service)
- Properly configured subnets (private OCP, private bare metal, public)
- Network Security Groups with correct naming patterns
- Security lists and route tables with appropriate rules

## How to use BYON

### **Step 1: Enable Existing Network Option**

When deploying OpenShift on OCI, you'll see a configuration option in the deployment form:

1. **Locate the Network Configuration Section**
2. **Check the "Use Existing Network" checkbox**
   - This enables the BYON mode for your deployment
   - Once checked, additional fields will appear for selecting your existing network resources

### **Step 2: Select Your Network Resources**

After enabling "Use Existing Network", you'll need to configure the following required fields:


### **Networking Compartment OCID**
- **Field**: "Networking Compartment OCID"
- **Description**: Compartment where the existing network resources are located. This may be different or same from the main compartment where OpenShift resources will be created

#### **Existing VCN Selection**
- **Field**: "Existing VCN"
- **Description**: Select the VCN that contains your existing network infrastructure within the compartment you selected
- **Requirements**: The VCN may or may not be in the same compartment and meet all OpenShift networking requirements

#### **Existing Subnet Selection**
You'll need to select three specific subnets:

1. **Existing Public Subnet**

2. **Existing Private Subnet for OCP**

3. **Existing Private Subnet for Bare Metal**


## Prerequisites for BYON

Before proceeding with BYON for OpenShift deployment, ensure your existing OCI network meets all the requirements outlined in this guide. Our validation module will automatically check these requirements, but it's important to understand what's needed.

## Required Network Resources
**Note**: If you used the `create-cluster` stack previously, your VCN already meets these requirements.

### **Core Network Infrastructure**

#### Virtual Cloud Network (VCN)
- **Resource**: `oci_core_vcn`
- **Requirements**:
  - Must be in `AVAILABLE` state
  - Must have sufficient CIDR blocks for OpenShift nodes and services
  - Must include DNS label configuration

#### Network Gateways (All Required)
Your existing VCN must have all three gateway types configured:

- **Internet Gateway**: `oci_core_internet_gateway`
  - **Purpose**: External connectivity for OpenShift load balancers and API access
  - **Requirement**: Must be attached and available in your VCN

- **NAT Gateway**: `oci_core_nat_gateway`
  - **Purpose**: Outbound internet access for private OpenShift nodes
  - **Requirement**: Must be attached and available in your VCN

- **Service Gateway**: `oci_core_service_gateway`
  - **Purpose**: Access to OCI services (Object Storage, Registry, etc.)
  - **Requirement**: Must be configured with OCI services and attached to your VCN

### **Subnet Configuration for BYON**

Your existing network must have three properly configured subnets:

#### Private OCP Subnet
- **Purpose**: Hosts OpenShift control plane and worker nodes
- **Requirements**:
  - Must be in `AVAILABLE` state
  - **Critical**: Must have `prohibit_public_ip_on_vnic = true`
  - Must use private route table (routes through NAT Gateway)
  - Must use private security list
  - Recommended size: `/24` or larger depending on cluster size

#### Private Bare Metal Subnet
- **Purpose**: Hosts bare metal worker nodes (if using bare metal instances)
- **Requirements**:
  - Must be in `AVAILABLE` state
  - **Critical**: Must have `prohibit_public_ip_on_vnic = true`
  - Must use private route table
  - Must use private security list
  - Should be sized appropriately for bare metal node count

#### Public Subnet
- **Purpose**: Hosts load balancers and bastion hosts
- **Requirements**:
  - Must be in `AVAILABLE` state
  - **Critical**: Must have `prohibit_public_ip_on_vnic = false`
  - Must use public route table (routes through Internet Gateway)
  - Must use public security list

### **Network Security Groups (NSGs) for BYON**

Your existing NSGs must follow specific naming patterns for automatic discovery:

#### Load Balancer NSG
- **Naming Convention**: Display name must contain `*lb*` (e.g., "cluster-lb-nsg")
- **Default Security Rules**: These are default rules present which OCI suggests to have, there is **NO** validation for these. Customer can have NSG rules as per their need
  - **Egress**: All protocols to `0.0.0.0/0`
  - **Ingress**: TCP port 6443 from `0.0.0.0/0` (Kubernetes API)
  - **Ingress**: TCP port 80 from `0.0.0.0/0` (HTTP traffic)
  - **Ingress**: TCP port 443 from `0.0.0.0/0` (HTTPS traffic)
  - **Ingress**: All protocols from VCN CIDR (internal communication)

#### Control Plane NSG
- **Naming Convention**: Display name must contain `*controlplane*` (e.g., "cluster-controlplane-nsg")
- **Default Security Rules**: These are default rules present which OCI suggests to have, there is **NO** validation for these. Customer can have NSG rules as per their need
  - **Egress**: All protocols to `0.0.0.0/0`
  - **Ingress**: All protocols from VCN CIDR

#### Compute NSG
- **Naming Convention**: Display name must contain `*compute*` (e.g., "cluster-compute-nsg")
- **Default Security Rules**: These are default rules present which OCI suggests to have, there is **NO** validation for these. Customer can have NSG rules as per their need
  - **Egress**: All protocols to `0.0.0.0/0`
  - **Ingress**: All protocols from VCN CIDR

### **Security Lists for BYON**

Your existing security lists must follow naming patterns:

#### Private Security List
- **Naming Convention**: Display name must contain `*private*`
- **Required Rules**:
  - **Ingress**: All protocols from VCN CIDR
  - **Egress**: All protocols to `0.0.0.0/0`

#### Public Security List
- **Naming Convention**: Display name must contain `*public*`
- **Required Rules**:
  - **Ingress**: All protocols from VCN CIDR
  - **Ingress**: TCP port 22 from `0.0.0.0/0` (SSH access)
  - **Egress**: All protocols to `0.0.0.0/0`

### **Route Tables for BYON**

Your existing route tables must follow naming patterns:

#### Private Route Table
- **Naming Convention**: Display name must contain `*private*`
- **Required Routes**:
  - Default route `0.0.0.0/0` → NAT Gateway
  - OCI Services CIDR → Service Gateway

#### Public Route Table
- **Naming Convention**: Display name must contain `*public*`
- **Required Routes**:
  - Default route `0.0.0.0/0` → Internet Gateway

## BYON Validation Process

Our validation module automatically checks your existing network infrastructure:

### **Automated Checks**
- ✅ VCN and subnet availability
- ✅ Gateway presence and configuration
- ✅ NSG discovery using naming patterns
- ✅ Security list discovery using naming patterns
- ✅ Route table discovery using naming patterns
- ✅ Subnet VNIC configuration validation

### **What Gets Validated**
1. **Resource States**: All resources must be in `AVAILABLE` state
2. **Network Security**: Proper VNIC settings for public/private subnets
3. **Naming Patterns**: Resources must follow the specified naming conventions
4. **Gateway Configuration**: All required gateways must be present and functional

## Troubleshooting BYON Issues

### **Common Validation Failures**

1. **Naming Pattern Issues**
   - Ensure NSGs, security lists, and route tables follow required naming patterns
   - Check for typos in resource names
   - **For `create-cluster` users**: The stack creates resources with correct naming patterns automatically

2. **Resource State Issues**
   - Verify all resources are in `AVAILABLE` state
   - Check for any pending operations on network resources

3. **Configuration Issues**
   - Verify subnet VNIC settings match requirements
   - Ensure all required security rules are present
   - Check route table configurations

4. **Gateway Issues**
   - Confirm all three gateway types are attached to the VCN
   - Verify gateway states and configurations

### **For Previous `create-cluster` Stack Users**
- **Resource Location**: Use OCI Console or CLI to locate resources created by the previous stack
- **Stack Outputs**: Check the Terraform stack outputs for resource IDs and configurations
- **State Verification**: Ensure no resources were modified or deleted since the original deployment

### **Getting Help**
- Review detailed error messages from the validation module
- Check OCI console for resource states and configurations
- Verify IAM permissions for network resource access
- For `create-cluster` stack users: Review the original stack configuration and outputs

## Next Steps

Once your network passes all BYON validations, you can proceed with OpenShift deployment using your existing network infrastructure. The deployment process will automatically discover and use your validated network resources.

**For users reusing `create-cluster` network**: You can now deploy additional OpenShift clusters using the same proven network infrastructure, optimizing costs and maintaining consistency across your OpenShift deployments.
