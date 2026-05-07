# Single shared KMS key for EKS secrets, RDS at-rest, and EBS volume encryption.
# Plan called for 3 separate keys ($3/mo idle) but collapsed to 1 ($1/mo) to fit
# the $100 budget. AWS best practice prefers separate keys for blast-radius
# isolation; revisit for production.

resource "aws_kms_key" "shared" {
  description             = "Shared encryption key for EKS secrets, RDS, and EBS in the bakery project."
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableRootPermissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "shared" {
  name          = "alias/bakery-shared"
  target_key_id = aws_kms_key.shared.key_id
}
