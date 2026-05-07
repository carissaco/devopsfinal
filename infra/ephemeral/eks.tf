module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_endpoint_cidrs
  cluster_endpoint_private_access      = true

  # v20 dropped aws-auth ConfigMap. Access is granted via EKS Access Entries.
  # This single flag makes the IAM principal running terraform a cluster admin.
  enable_cluster_creator_admin_permissions = true

  # Encrypt cluster secrets with the shared KMS key from the persistent stack.
  cluster_encryption_config = {
    provider_key_arn = local.kms_key_arn
    resources        = ["secrets"]
  }

  # Managed addons. The module installs and upgrades these for us.
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.irsa_ebs_csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Single managed node group, on-demand t3.medium x2 in private subnets.
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      disk_size = 30
    }
  }
}
