terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
  }

  backend "s3" {
    bucket         = "usfcarissa-bakery-tfstate"
    key            = "ephemeral/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bakery-tflock"
    encrypt        = true
  }
}
