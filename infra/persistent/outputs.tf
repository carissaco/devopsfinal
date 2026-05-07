output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by service name. Use these as Helm image.repository values."
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the apex domain."
  value       = aws_route53_zone.main.zone_id
}

output "hosted_zone_name_servers" {
  description = "Update your registrar's nameservers to these 4 values so DNS resolves through Route 53."
  value       = aws_route53_zone.main.name_servers
}

output "acm_certificate_arn" {
  description = "ARN of the wildcard ACM certificate. Reference this in ALB Ingress annotations."
  value       = aws_acm_certificate_validation.wildcard.certificate_arn
}

output "kms_key_arn" {
  description = "ARN of the shared KMS key. Use for EKS cluster encryption + RDS storage encryption."
  value       = aws_kms_key.shared.arn
}

output "kms_key_id" {
  description = "ID of the shared KMS key."
  value       = aws_kms_key.shared.key_id
}

output "domain_name" {
  description = "Apex domain name."
  value       = var.domain_name
}
