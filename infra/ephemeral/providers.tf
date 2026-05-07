provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "bakery"
      Env     = "shared"
      Managed = "terraform"
      Stack   = "ephemeral"
    }
  }
}

# Kubernetes & Helm providers wired off the EKS cluster outputs. They use
# `aws eks get-token` so kubeconfig stays in sync with whatever AWS credentials
# you're running terraform with.

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}
