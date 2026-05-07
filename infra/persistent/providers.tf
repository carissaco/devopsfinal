provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = "bakery"
      Env     = "shared"
      Managed = "terraform"
      Stack   = "persistent"
    }
  }
}

data "aws_caller_identity" "current" {}
