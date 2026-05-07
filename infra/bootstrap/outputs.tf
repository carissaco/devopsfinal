output "state_bucket_name" {
  description = "Use this for -backend-config=\"bucket=...\" in persistent and ephemeral stacks."
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "Use this for -backend-config=\"dynamodb_table=...\" in persistent and ephemeral stacks."
  value       = aws_dynamodb_table.tflock.name
}

output "aws_region" {
  description = "Region the bucket and table are in."
  value       = var.aws_region
}
