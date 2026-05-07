variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Apex domain name (you must own this and update its nameservers at the registrar after apply)."
  type        = string
  default     = "usfcar.xyz"
}

variable "service_names" {
  description = "Names of the application services that get an ECR repo each."
  type        = list(string)
  default     = ["catalog-svc", "inventory-svc", "orders-svc", "web"]
}
