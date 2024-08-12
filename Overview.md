
We will have TF installed on our VM/Laptop. We will install TF on our VM, we will connect TF to our AWS account, whenever anyone executes the TF Project, it will create a VPC, and within the VPC, it will create a EKS cluster.

The EKS Cluster will have autoscaling, which will create VM/EC2 Instances, min desired state would be 2 and max would be 6 when there is more traffic. 

Note - By default worker node for our EKS cluster would be 2. Nodes can automatically scale upto 6 in case when laod increases on resources.



GIT REPO - https://github.com/iam-veeramalla/terraform-eks

# PREREQUISITE

https://docs.aws.amazon.com/eks/latest/userguide/setting-up.html

1. Install AWS CLI 
To check if AWS CLI has been installed or not run aws --version command.
    aws --version
    aws-cli/2.15.25 Python/3.11.8 Darwin/23.1.0 source/arm64 prompt/off

2. Install TF  - use brew to install TF. Once it is complete, you can run terraform version to check if it installed or not.

    amitdhanik@Amits-MacBook-Air EKS Cluster with VPC Using TF % terraform version
    Terraform v1.7.4
    on darwin_arm64

    Your version of Terraform is out of date! The latest version
    is 1.9.3. You can update by downloading from https://www.terraform.io/downloads.html

3. Connect TF to AWS

    Run aws configure command to connect to AWS. You have to put in the ACCESS KEY, SECRET ACCESS KEY. Create IAM user, and provide the access and secret key for same.

    Now TF will use the secret credentials that you have configured using aws configure command on your laptop.

4. Execute TF files to create resources on AWS


# BEST PRACTISE TO WRITE CODE WITH TF

1. Always break down the resources that you want to create usig TF in a no of steps, and write file separately for them. Dont write code for all in one main.tf file, as its not readable. Maintain diff file for each AWS Service.

2. Always try to use Modules as much as possible. Modules are repeatable piece of code, whcih can be shared and reused at any other point of time. Inbuilt modules can be used which are widely available for all AWS services.
If inbuilt modules are not present, write the code, convert it into module, and you are ready to go.


# VPC

So we have inbuilt VPC module already provided by TF. If you search - terraform-aws-modules/vpc/aws, you can search here all the modules. Here we have our instructions

Provision Instructions
Copy and paste into your Terraform configuration, insert the variables, and run terraform init:

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.12.0"
}

It is important to mention the version of module you are using, as TF will cause an issue if your infra was on a older version and a new version was released. It will try to take the latest version by default.

resource "random_string" "suffix" {
  length  = 8
  special = false
}

We have used a string so that our EKS cluster gets a unique name every time its crated.

# Explained creation of VPC

1. For cidr, instead of having a fixed value, we have passed it as a variable, so that in case we want to have diff CIDR range for creating another VPC, it can be done with ease.

2. Why we have not used hard coded AZs? and instead made use of dynamic selection?

    azs  = data.aws_availability_zones.available.names

Passing Availability Zones (AZs) using a data source like `data.aws_availability_zones.available.names` instead of hard-coding them as `["eu-west-1a", "eu-west-1b", "eu-west-1c"]` is considered good practice in Terraform for several reasons:

**Dynamic Selection and Future-Proofing**
   - **Hard-Coded AZs**: If you hard-code AZs, your configuration is fixed to those specific AZs. If AWS adds, removes, or renames AZs in the region, your Terraform code will not automatically adapt, potentially leading to issues during deployment or updates.
   - **Dynamic AZs**: Using `data.aws_availability_zones.available.names` allows your configuration to automatically pick up all available AZs in the region. If there are changes in the AZs provided by AWS, your Terraform code will adapt without requiring manual updates.

Read more in why AZ are used dynamically.

3. We have created 2 private subnet and 2 public subnet. For private subnet to connect to internet, we need NAT gateways. Now here are 3 conditions 

    One NAT Gateway per subnet (default behavior)
        enable_nat_gateway = true
        single_nat_gateway = false
        one_nat_gateway_per_az = false
        
    Single NAT Gateway
        enable_nat_gateway = true
        single_nat_gateway = true
        one_nat_gateway_per_az = false

    One NAT Gateway per availability zone
        enable_nat_gateway = true
        single_nat_gateway = false
        one_nat_gateway_per_az = true

Since we are using single_nat_gateway = true, If single_nat_gateway = true, then all private subnets will route their Internet traffic through this single NAT gateway. The NAT gateway will be placed in the first public subnet in your public_subnets block.

3.   enable_dns_hostnames = true
     enable_dns_support = true  

The parameters `enable_dns_hostnames` and `enable_dns_support` are valid and commonly used when creating a VPC in AWS, even though you might not see them explicitly listed in the module documentation for `terraform-aws-modules/vpc/aws`. Here's what they do:

### 1. **`enable_dns_hostnames`**
   - **Purpose**: This parameter controls whether instances launched into the VPC get public DNS hostnames. 
   - **Default Behavior**: If set to `true`, instances with a public IP address will also receive a public DNS name. This is particularly useful if you want to access instances via their DNS names.
   - **Use Case**: This is typically enabled when you require DNS hostnames for instances, especially when using services that rely on DNS.

### 2. **`enable_dns_support`**
   - **Purpose**: This parameter controls whether DNS resolution is supported for the VPC.
   - **Default Behavior**: When set to `true`, the VPC's DNS server is used for DNS resolution within the VPC.
   - **Use Case**: It's essential for most VPC configurations, especially if you're using private DNS, or services that rely on AWS DNS, like Route 53.

4. Tags for public and private subnets

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

These are provided because 

- **`kubernetes.io/role/elb`** (in `public_subnet_tags`): This tag is used to identify subnets that should be used for external load balancers (ELBs). When you create an ELB in AWS for a Kubernetes service of type `LoadBalancer`, Kubernetes looks for subnets with this tag to place the ELB.

- **`kubernetes.io/role/internal-elb`** (in `private_subnet_tags`): This tag is used to identify subnets that should be used for internal load balancers (ILBs). When you create an ILB in AWS for a Kubernetes service, Kubernetes looks for subnets with this tag to place the ILB.

# Provider definition - Why we have created a separate provider.tf

Both approaches you've mentioned are technically correct, but they serve slightly different purposes and follow different practices. Let's break down each one and understand the differences:


1. **Required Providers Block**:
   - **Your Approach**: By specifying `required_providers` in a `terraform` block, you're explicitly stating which version of the AWS provider to use. This is crucial for ensuring compatibility and avoiding unexpected behavior due to provider updates.
   - **Instructor's Approach**: Does not specify the `required_providers` block, meaning Terraform will use the latest version of the provider that matches the existing constraints in the project (or the version it finds in the provider cache).

2. **Version Control**:
   - **Your Approach**: By locking the AWS provider version to `~> 5.0`, you ensure that your configuration remains compatible with the 5.x versions of the AWS provider, avoiding breaking changes that could come with a major version update.
   - **Instructor's Approach**: There's no version specified, so it might use the latest available version. This could lead to potential issues if the provider introduces breaking changes in future versions.

### Which One is Correct?
- **Both are Correct**: Both approaches will work, but your approach of separating the provider configuration into a dedicated `provider.tf` file is generally considered better practice for larger, more complex projects.
  
### Summary:
- **Instructor's Approach**: Quick and effective for simple or small Terraform configurations, but lacks the organization and version control best practices.
- **Your Approach**: More modular, maintainable, and adheres to best practices for version control, making it a better choice for larger or long-term projects.

In professional environments or larger projects, your approach is preferred because it ensures better organization, version control, and scalability.


# What happens to creating of IGW, public/private Route tables,aws_route_table_association, S.G., EIP

You msut be wondering why we have not created IGW, route table in his vpc.tf file. Are they not necessary? i think for a subnet to be public, its route must consist of IGW. If we are creating only like below, will the public subnet still be created? or somehow the module might create the IGW and route table in backend? 

also there must be 2 route table right? one for private and one for public. here both are not given. what would happend..

Ans to all in IGW, ROUTE TABLE.md documentation

# Setting up EKS Cluster

1. enable_irsa = true  --> oidc_provider_arn =	The ARN of the OIDC Provider if enable_irsa = true

2. vpc_id and subnet_id values we can refer from module vpc which we created in vpc.tf

3. In the eks_managed_node_group_defaults, we have to pass the S.G as well, so we need to create a S.G tf file as well

4. In the eks_managed_node_group_defaults, we have given the ami_type, instance_types, and the vpc_security_group_ids,while in eks_managed_node_groups, we have only provided the max and min no of nodes in our cluster.

# Error 1

we cant directly run tf plan, as we have written eks.tf file later. we have to run tf init to install all modules required.

on eks-cluster.tf line 1:
│    1: module "eks" {
│ 
│ This module is not yet installed. Run "terraform init" to install all modules required by this configuration.

# Error 2

 on security-groups.tf line 11, in resource "aws_vpc_security_group_ingress_rule" "allow_worker_mgmt_ingress":
│   11:   cidr_ipv4         = ["10.0.0.0/0","172.16.0.0/12", "192.168.0.0/16",]

Since we are making use of resource "aws_security_group" & resource "aws_vpc_security_group_ingress_rule" , contrary to what was being used earlier - resource "aws_security_group_rule", so TF wants us to pass single CIDR for each resource. It expects a string, not a list of strings, which could be done in resource "aws_security_group_rule".


Single CIDR per Rule: Each rule handles a single cidr_ipv4 block. Terraform doesn't allow multiple CIDR blocks in one aws_vpc_security_group_ingress_rule resource.
Separate Resources: You create a new aws_vpc_security_group_ingress_rule resource for each CIDR block.


# Terraform init

Once you run terraform init, it downloads all the modules,providers and this is all located in .terraform folder

/Users/amitdhanik/EKS Cluster with VPC Using TF/.terraform/modules
amitdhanik@Amits-MacBook-Air modules % ls -ltr
    total 8
    drwxr-xr-x@ 20 amitdhanik  staff   640 Aug  9 18:35 vpc
    drwxr-xr-x@ 23 amitdhanik  staff   736 Aug 10 18:56 eks
    drwxr-xr-x@ 16 amitdhanik  staff   512 Aug 10 18:56 eks.kms
    -rw-r--r--@  1 amitdhanik  staff  1091 Aug 10 18:56 modules.json

Inside provider - /Users/amitdhanik/EKS Cluster with VPC Using TF/.terraform/providers/registry.terraform.io/hashicorp

    amitdhanik@Amits-MacBook-Air hashicorp % ls -ltr
    total 0
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug  9 18:35 aws
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug  9 18:35 random
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug 10 18:56 tls
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug 10 18:56 time
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug 10 18:56 cloudinit
    drwxr-xr-x@ 3 amitdhanik  staff  96 Aug 10 18:56 null

# Terraform plan

Once tf plan is completed, and the EKS cluster is ready. You need to click on access and add access role for you to see nodes under compute .

Under resources, you can see deployment, daemon set and pods as well

You can verify the VPC creation as well.
