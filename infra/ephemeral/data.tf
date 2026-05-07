data "aws_caller_identity" "current" {}

data "terraform_remote_state" "persistent" {
  backend = "s3"

  config = {
    bucket = "usfcarissa-bakery-tfstate"
    key    = "persistent/terraform.tfstate"
    region = "us-east-1"
  }
}

# Convenience locals so other files don't repeat data.terraform_remote_state.persistent.outputs.*
locals {
  ecr_urls            = data.terraform_remote_state.persistent.outputs.ecr_repository_urls
  hosted_zone_id      = data.terraform_remote_state.persistent.outputs.hosted_zone_id
  acm_certificate_arn = data.terraform_remote_state.persistent.outputs.acm_certificate_arn
  kms_key_arn         = data.terraform_remote_state.persistent.outputs.kms_key_arn
  domain_name         = data.terraform_remote_state.persistent.outputs.domain_name
}
