output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Run this to wire kubectl to the new cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "rds_endpoint" {
  description = "RDS endpoint hostname (only reachable from inside the VPC)."
  value       = module.rds.db_instance_endpoint
}

output "rds_host" {
  description = "RDS endpoint hostname only (no port). Used for ExternalName Service."
  value       = module.rds.db_instance_address
}

output "rds_secret_arn" {
  description = "ARN of the auto-generated RDS master password Secret in AWS Secrets Manager. Reference this from ESO's ExternalSecret."
  value       = module.rds.db_instance_master_user_secret_arn
}

output "argocd_initial_password_command" {
  description = "Run this after apply to get the initial Argo CD admin password."
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "irsa_role_arns" {
  description = "IRSA role ARNs by purpose. Argo CD app values can reference these."
  value = {
    aws_load_balancer_controller = module.irsa_lb_controller.iam_role_arn
    cert_manager                 = module.irsa_cert_manager.iam_role_arn
    external_dns                 = module.irsa_external_dns.iam_role_arn
    external_secrets             = module.irsa_external_secrets.iam_role_arn
    ebs_csi                      = module.irsa_ebs_csi.iam_role_arn
  }
}
