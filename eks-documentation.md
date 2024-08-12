Let's break down the creation of an EKS cluster in AWS using Terraform and how different components are managed:

### 1. **Control Plane (Master Plane)**
   - **What is it?**: The control plane in EKS is fully managed by AWS and includes the Kubernetes API server, etcd (key-value store), and other critical components. It controls and manages the Kubernetes cluster.
   - **How is it created?**: 
     - The control plane is created automatically when you create an EKS cluster. In your Terraform code, it's primarily set up through the `cluster_name`, `cluster_version`, `vpc_id`, and `subnet_ids` (for where the control plane will reside) parameters.
     - The control plane is managed by AWS and is not exposed for direct management by users.

   - **Code Related**:
     ```hcl
     module "eks" {
       ...
       cluster_name    = local.cluster_name
       cluster_version = var.kubernetes_version
       vpc_id          = module.vpc.vpc_id 
       subnet_ids      = module.vpc.private_subnets
       control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]
       ...
     }
     ```

### 2. **Worker Nodes (Node Groups)**
   - **What are they?**: Worker nodes are the EC2 instances where your Kubernetes workloads (pods) run. These nodes connect to the control plane and are managed via Kubernetes.
   - **How are they created?**:
     - The worker nodes are defined in the `eks_managed_node_groups` block within the module. The `eks_managed_node_groups` parameter defines the configuration for the node groups, including instance types, desired size, and scaling configurations.
     - `eks_managed_node_group_defaults` provides default settings for all managed node groups, such as AMI type and instance type.

   - **Code Related**:
     ```hcl
     eks_managed_node_group_defaults = {
       ami_type        = "AL2_x86_64"
       instance_types = ["t3.medium"]
       vpc_security_group_ids = [aws.security_group.all_worker_mgmt.id]
     }

     eks_managed_node_groups = {
       node_group = {
         min_size     = 2
         max_size     = 6
         desired_size = 2
       }
     }
     ```

### 3. **Backend Resources Created by the Module**
   - **VPC Resources**: The module creates the necessary VPC resources (subnets, route tables, etc.) if you haven't provided them. In your case, you are using an existing VPC, so you pass `vpc_id` and `subnet_ids` to the module.
   - **Security Groups**: The module will create security groups if you don't provide your own. These security groups will control access to the EKS control plane and worker nodes.
   - **IAM Roles and Policies**: The module creates IAM roles and policies required by the EKS cluster and node groups.

### 4. **Difference Between `eks_managed_node_group_defaults` and `eks_managed_node_groups`**
   - **`eks_managed_node_group_defaults`**:
     - Provides default settings that apply to all EKS managed node groups.
     - For example, if you set `ami_type` and `instance_types` here, those values will be used for all node groups unless overridden in `eks_managed_node_groups`.

   - **`eks_managed_node_groups`**:
     - Defines individual node groups with specific settings.
     - This is where you specify details like the number of instances, scaling settings, and any overrides to the defaults set in `eks_managed_node_group_defaults`.

### 5. **Internet Gateway (IGW) and Route Tables**
   - In many cases, the EKS module will automatically create an Internet Gateway and route tables if public subnets are provided.
   - Public subnets typically require a route table that routes traffic to the Internet Gateway, allowing your worker nodes to communicate with the internet (if needed).

### Summary:
- **Control Plane**: Managed by AWS, set up with `cluster_name`, `cluster_version`, `vpc_id`, etc.
- **Worker Nodes**: Defined via `eks_managed_node_groups`, with defaults in `eks_managed_node_group_defaults`.
- **Backend Resources**: The module can create VPC resources, security groups, IAM roles, etc.
- **Internet Gateway and Route Tables**: Handled by the module if public subnets are involved.

This setup ensures that your EKS cluster is properly configured with AWS best practices.