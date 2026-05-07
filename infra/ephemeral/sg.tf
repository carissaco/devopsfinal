resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds"
  description = "Postgres access from EKS worker nodes only."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "rds_from_eks_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Postgres from EKS node SG"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Egress all (default AWS behavior; outbound traffic is fine for an RDS instance)"
}
