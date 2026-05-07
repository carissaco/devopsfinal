variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "bakery"
}

variable "cluster_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for the VPC. Pin to two for cost (single NAT). RDS still requires subnets in 2+ AZs."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_endpoint_cidrs" {
  description = "CIDRs allowed to reach the EKS public API endpoint. Default 0.0.0.0/0 — fine since the endpoint requires valid IAM authn. Lock down to your IP for stricter posture."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS managed node group. Stay on amd64 — the Java catalog image is amd64-only."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 3
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "rds_instance_class" {
  description = "RDS instance class. db.t4g.micro is ARM-based and cheapest; Postgres ARM is well-supported."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

variable "rds_engine_version" {
  type    = string
  default = "16.4"
}
