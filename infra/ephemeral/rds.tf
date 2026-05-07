module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.10"

  identifier = "bakery"

  engine               = "postgres"
  engine_version       = var.rds_engine_version
  family               = "postgres16"
  major_engine_version = "16"
  instance_class       = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage
  storage_encrypted = true
  kms_key_id        = local.kms_key_arn

  db_name  = "bakery"
  username = "bakery"
  port     = 5432

  # Auto-generate password and store in Secrets Manager. Password never touches
  # TF state. ESO syncs it from Secrets Manager into the K8s `bakery-db` Secret.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = local.kms_key_arn

  multi_az            = false
  publicly_accessible = false

  # The RDS module creates its own subnet group from these.
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [aws_security_group.rds.id]
  create_db_subnet_group = true

  # Lab settings — bump these for a real production deployment.
  skip_final_snapshot     = true
  backup_retention_period = 0
  deletion_protection     = false

  performance_insights_enabled = false
  monitoring_interval          = 0

  # Avoid surprise version upgrades during lab work.
  apply_immediately   = true
  auto_minor_version_upgrade = false
}
