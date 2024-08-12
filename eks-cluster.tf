module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  enable_irsa = true 

#   cluster_endpoint_public_access  = true

#   cluster_addons = {
#     coredns                = {}
#     eks-pod-identity-agent = {}
#     kube-proxy             = {}
#     vpc-cni                = {}
#   }

  vpc_id                   = module.vpc.vpc_id 
  subnet_ids               = module.vpc.private_subnets
  #control_plane_subnet_ids = ["subnet-xyzde987", "subnet-slkjf456", "subnet-qeiru789"]

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type        = "AL2_x86_64"
    instance_types = ["t3.medium"]
    vpc_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  }

  eks_managed_node_groups = {
    node_group = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
    #   ami_type       = "AL2023_x86_64_STANDARD"
    #   instance_types = ["m5.xlarge"]

      min_size     = 2
      max_size     = 6
      desired_size = 2
    }
  }

  tags = {
    cluster = "demo"
  }
}