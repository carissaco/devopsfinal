terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  backend "s3" {
    bucket         = "usfcarissa-bakery-tfstate"
    key            = "persistent/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bakery-tflock"
    encrypt        = true
  }
}
