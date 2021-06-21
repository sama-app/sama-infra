provider "aws" {
  profile = "default"
  region  = local.region
}


###########
### RDS ###
###########

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "sama-${var.environment}"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "postgres"
  engine_version       = "13.2"
  family               = "postgres13"
  major_engine_version = "13"
  instance_class       = "db.t3.micro"

  allocated_storage = 20
  storage_encrypted = false

  name                   = "sama"
  username               = "postgres"
  create_random_password = true
  random_password_length = 12
  port                   = 5432

  multi_az               = false
  subnet_ids             = var.subnets
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  performance_insights_enabled = false
  create_monitoring_role       = false

  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = local.tags
}

module "rds_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "rds-security-group-${var.environment}"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks =var.vpc_cidr_block
    },
  ]


  tags = local.tags
}