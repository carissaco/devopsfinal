# Cluster-level Kubernetes resources that bridge AWS to the cluster:
# - bakery namespace where apps live
# - ExternalName Service so app charts can use a stable `bakery-db` hostname that
#   transparently resolves to the dynamic RDS endpoint
# - ESO ClusterSecretStore so any chart can pull from AWS Secrets Manager via
#   the IRSA role on the external-secrets controller SA

resource "kubernetes_namespace" "bakery" {
  metadata {
    name = "bakery"
  }

  depends_on = [module.eks]
}

resource "kubernetes_service" "bakery_db" {
  metadata {
    name      = "bakery-db"
    namespace = kubernetes_namespace.bakery.metadata[0].name
  }

  spec {
    type          = "ExternalName"
    external_name = module.rds.db_instance_address
  }

  # The AWS LB Controller's mutating admission webhook intercepts every Service
  # creation cluster-wide. Wait for it to be healthy before creating Services.
  depends_on = [helm_release.aws_load_balancer_controller]
}

resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = "external-secrets"
                namespace = "external-secrets"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}
