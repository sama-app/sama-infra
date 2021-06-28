provider "aws" {
  profile = "default"
  region  = local.region
}

resource "aws_lb_target_group" "monitoring" {
  name        = "monitoring-tg-${terraform.workspace}"
  protocol    = "HTTP"
  port        = 3000
  vpc_id      = local.env.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 15
    path                = "/api/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    protocol            = "HTTP"
    matcher             = "200-299"
  }
}

resource "aws_lb_target_group_attachment" "monitoring" {
  target_group_arn = aws_lb_target_group.monitoring.arn
  target_id        = module.monitoring.id[0]
  port             = 3000
}

resource "aws_lb_listener_rule" "monitoring" {
  listener_arn = local.env.lb_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring.arn
  }

  condition {
    host_header {
      values = [local.env.grafana_domain]
    }
  }
}

# Deployment
module "monitoring" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name = "monitoring-${terraform.workspace}"

  instance_count = 1
  ami            = var.ami_id
  instance_type  = "t2.micro"

  vpc_security_group_ids = [
  module.monitoring_sg.security_group_id]
  subnet_id                   = local.env.subnet_id
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.monitoring.name

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
      description = "grafana port"
      cidr_blocks = local.env.vpc_cidr_blocks
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "TCP"
      description = "prometheus port"
      cidr_blocks = local.env.vpc_cidr_blocks
    },
    {
      from_port   = 9100
      to_port     = 9100
      protocol    = "TCP"
      description = "metrics port"
      cidr_blocks = local.env.vpc_cidr_blocks
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      description = "SSH"
      cidr_blocks = local.env.vpc_cidr_blocks
    }
  ]

  egress_rules = [
    "all-all"
  ]
}

resource "aws_iam_instance_profile" "monitoring" {
  name = "monitoring-instance-profile-${terraform.workspace}"
  role = aws_iam_role.monitoring.name
}

resource "aws_iam_role" "monitoring" {
  name = "monitoring-role-${terraform.workspace}"
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
