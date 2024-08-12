The `terraform-aws-modules/vpc/aws` module simplifies the creation of a VPC by automatically handling many of the resources and configurations that are typically needed, including Internet Gateways (IGWs), NAT Gateways, route tables, and their associations. Here's how it works:

### 1. **Internet Gateway (IGW)**
   - **Automatic Creation**: The module automatically creates an Internet Gateway (IGW) if you provide `public_subnets` and if those subnets need to have outbound internet access (which is typically the case).
   - **Public Subnet Requirements**: For a subnet to be public, it must have a route in its route table that directs 0.0.0.0/0 (all internet traffic) to an IGW. The module ensures this is done by associating the public subnets with a route table that includes a route to the IGW.

### 2. **Route Tables**
   - **Automatic Creation**: The module automatically creates two route tables:
     - **Public Route Table**: Associated with the public subnets and includes a route to the IGW for internet access.
     - **Private Route Table**: Associated with the private subnets and typically includes a route to the NAT Gateway for outbound internet access while keeping the instances private.
   - **Route Table Associations**: The module takes care of associating the correct route tables with the appropriate subnets (public or private) based on the subnet configuration you provide.

### 3. **Summary of What Happens**
   - **Public Subnets**: The module creates the necessary IGW, public route table, and routes to make the subnets specified in `public_subnets` truly public.
   - **Private Subnets**: The module creates the necessary private route table and routes (including NAT Gateway routes) to ensure that subnets specified in `private_subnets` remain private but still have outbound internet access.

### 4. **What Happens If You Don't Manually Create IGW and Route Tables?**
   - **Using the Module**: If you're using the `terraform-aws-modules/vpc/aws` module as shown, you don't need to manually create the IGW and route tables because the module automatically handles this for you.
   - **Public Subnets**: The public subnets will be created with the appropriate IGW and route table configurations, making them fully functional as public subnets.
   - **Private Subnets**: Similarly, private subnets will have the correct route tables with NAT Gateway routes, ensuring they remain private.

### 5. **Best Practices**
   - **Rely on the Module**: When using a well-established module like `terraform-aws-modules/vpc/aws`, it's often best to rely on the module's built-in functionality rather than manually creating resources. This reduces complexity and potential errors.
   - **Customization**: If you need custom configurations, the module allows for various overrides and customizations, but for standard VPC setups, the default behavior of the module usually suffices.

### Example:
With the configuration you provided:

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.12.0"

  name            = "my-vpc"
  cidr            = var.vpc_cidr
  azs             = data.aws_availability_zones.available.names
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostnames = true
  enable_dns_support   = true  

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
```

- **Public subnets** (`10.0.4.0/24`, `10.0.5.0/24`) will have an IGW and a public route table automatically created and associated with them.
- **Private subnets** (`10.0.1.0/24`, `10.0.2.0/24`) will have a private route table with routes to a NAT Gateway automatically created and associated with them.

The module does everything necessary to set up both public and private subnets correctly. You don't need to manually create an IGW or route tables unless you need a highly customized setup.