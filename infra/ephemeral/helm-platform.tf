# Platform Helm releases — installed by Terraform because they need IAM role
# ARNs (from IRSA modules above) injected into ServiceAccount annotations.
# Once Argo CD is up, application charts (catalog/inventory/orders/web,
# argo-rollouts, kube-prometheus-stack, loki) are managed by Argo CD instead.

# --- AWS Load Balancer Controller ---
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.4"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_lb_controller.iam_role_arn
  }

  depends_on = [module.eks]
}

# --- cert-manager ---
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.16.1"

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_cert_manager.iam_role_arn
  }

  # cert-manager needs to be able to assume the IRSA role; this requires the
  # securityContext fsGroup to match (CNI uses /var/run/secrets/...).
  set {
    name  = "securityContext.fsGroup"
    value = "1001"
  }

  # ALB controller's mutating webhook intercepts Service creations cluster-wide.
  # Wait for it to be healthy before installing charts that create Services.
  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller,
  ]
}

# --- ExternalDNS ---
resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "external-dns"
  create_namespace = true
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  version          = "1.15.0"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_external_dns.iam_role_arn
  }

  set {
    name  = "txtOwnerId"
    value = var.cluster_name
  }

  set {
    name  = "domainFilters[0]"
    value = local.domain_name
  }

  set {
    name  = "policy"
    value = "sync" # delete records when Ingress/Service is deleted
  }

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller,
  ]
}

# --- External Secrets Operator ---
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.10.4"

  set {
    name  = "installCRDs"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_external_secrets.iam_role_arn
  }

  depends_on = [
    module.eks,
    helm_release.aws_load_balancer_controller,
  ]
}

# --- Argo CD ---
# After install, get the initial admin password with:
#   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.6.12"

  # Argo CD self-signs and terminates TLS at the pod by default. The ALB
  # terminates TLS at the edge, so we run argocd-server with `--insecure`
  # (HTTP-only inside the cluster) and let the ALB own the cert.
  values = [
    yamlencode({
      configs = {
        params = {
          "server.insecure" = true
        }
      }
      server = {
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = true
          ingressClassName = "alb"
          hostname         = "argocd.usfcar.xyz"
          annotations = {
            "alb.ingress.kubernetes.io/scheme"                 = "internet-facing"
            "alb.ingress.kubernetes.io/target-type"            = "ip"
            "alb.ingress.kubernetes.io/listen-ports"           = "[{\"HTTP\":80},{\"HTTPS\":443}]"
            "alb.ingress.kubernetes.io/ssl-redirect"           = "443"
            "alb.ingress.kubernetes.io/group.name"             = "bakery"
            "cert-manager.io/cluster-issuer"                   = "letsencrypt-prod"
            "external-dns.alpha.kubernetes.io/hostname"        = "argocd.usfcar.xyz"
          }
          tls = true
        }
      }
    })
  ]

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.cert_manager,
    helm_release.external_dns,
    helm_release.external_secrets,
  ]
}

# --- db-bootstrap (creates the 3 schemas in RDS, syncs RDS password into K8s) ---
# Lives in TF (not Argo CD) so the dynamic RDS secret ARN flows from
# module.rds outputs without any per-session manual edits.
resource "helm_release" "db_bootstrap" {
  name      = "db-bootstrap"
  namespace = kubernetes_namespace.bakery.metadata[0].name
  chart     = "${path.module}/../../charts/db-bootstrap"

  set {
    name  = "rdsSecretArn"
    value = module.rds.db_instance_master_user_secret_arn
  }

  depends_on = [
    kubernetes_manifest.cluster_secret_store,
    kubernetes_service.bakery_db,
    module.rds,
  ]
}
