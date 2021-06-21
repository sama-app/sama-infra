provider "aws" {
  profile = "default"
  region = local.region
}

module "monitoring"  {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = "monitoring-${terraform.workspace}"

  instance_count         = 1
  ami                    = var.ami_id
  instance_type          = "t2.micro"

  vpc_security_group_ids = [module.monitoring_sg.security_group_id]
  subnet_id              = local.env.subnet_id
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

  ebs_block_device = [
    {
      device_name = "/dev/sda1"
      volume_type = "gp2"
      volume_size = 8
      encrypted   = false
    }
  ]

  key_name               = local.env.key_name
  monitoring             = false

  tags = local.tags
}

module "monitoring_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "monitoring-sg-${terraform.workspace}"
  description = "Security group for monitoring"
  vpc_id      = local.env.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "TCP"
      description = "application port"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "TCP"
      description = "application port"
      cidr_blocks = "10.0.0.0/16"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "SSH"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_rules        = ["all-all"]
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "monitoring-instance-profile-${terraform.workspace}"
  role = aws_iam_role.monitoring.name
}

resource "aws_iam_role" "monitoring" {
  name = "monitoring-role-${terraform.workspace}"
  path = "/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
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
