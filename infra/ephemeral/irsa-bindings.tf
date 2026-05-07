# IAM Roles for Service Accounts (IRSA). Each role is bound to a specific
# Kubernetes ServiceAccount in a specific namespace via the cluster's OIDC
# provider. The corresponding Helm chart (in helm-platform.tf) annotates its
# ServiceAccount with the role ARN.

# --- EBS CSI driver (referenced by the EKS module's aws-ebs-csi-driver addon) ---
# Uses AWS-managed policy instead of the IAM module's `attach_ebs_csi_policy`
# helper, which is missing ec2:DescribeAvailabilityZones (required by EBS CSI
# driver v1.59+).
module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.45"

  role_name = "${var.cluster_name}-ebs-csi"

  role_policy_arns = {
    ebs_csi = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

# --- AWS Load Balancer Controller ---
module "irsa_lb_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.45"

  role_name                              = "${var.cluster_name}-aws-lb-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# --- cert-manager (DNS-01 challenges via Route 53) ---
module "irsa_cert_manager" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.45"

  role_name                     = "${var.cluster_name}-cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${local.hosted_zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["cert-manager:cert-manager"]
    }
  }
}

# --- ExternalDNS (manages Route 53 records based on Ingress/Service annotations) ---
module "irsa_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.45"

  role_name                     = "${var.cluster_name}-external-dns"
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = ["arn:aws:route53:::hostedzone/${local.hosted_zone_id}"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-dns:external-dns"]
    }
  }
}

# --- External Secrets Operator (reads from AWS Secrets Manager) ---
# No built-in helper in the iam module, so we attach a custom policy.

module "irsa_external_secrets" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.45"

  role_name = "${var.cluster_name}-external-secrets"

  role_policy_arns = {
    eso = aws_iam_policy.external_secrets.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets"
  description = "ESO reads secrets from AWS Secrets Manager."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = local.kms_key_arn
      },
    ]
  })
}
