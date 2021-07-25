provider "aws" {
  profile = "default"
  region  = local.region
}

# Deployment
module "prometheus" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name = "prometheus-${terraform.workspace}"

  instance_count = 1
  ami            = var.ami_id
  instance_type  = "t2.micro"

  vpc_security_group_ids = [
  module.prometheus_sg.security_group_id]
  subnet_id                   = local.env.subnet_id
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.prometheus.name

  root_block_device = [
    {
      delete_on_termination = false
      volume_type           = "gp2"
      volume_size           = 20
      encrypted             = false
    }
  ]

  key_name   = local.env.key_name
  monitoring = false

  user_data = filebase64("${path.module}/scripts/deploy.sh")

  tags = local.tags
}


module "prometheus_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "prometheus-sg-${terraform.workspace}"
  description = "Security group for prometheus"
  vpc_id      = local.env.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "TCP"
      description = "prometheus port"
      cidr_blocks = local.env.vpc_cidr_block
    },
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "TCP"
      description = "metrics port"
      cidr_blocks = local.env.vpc_cidr_block
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "SSH"
      cidr_blocks = local.env.vpc_cidr_block
    }
  ]

  egress_rules = [
    "all-all"
  ]
}

resource "aws_iam_instance_profile" "prometheus" {
  name = "prometheus-instance-profile-${terraform.workspace}"
  role = aws_iam_role.prometheus.name
}

resource "aws_iam_role" "prometheus" {
  name = "prometheus-role-${terraform.workspace}"
  path = "/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
  ]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}
