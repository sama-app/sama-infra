locals {
  region = "eu-central-1"

  tags = {
    Environment = var.environment
  }
}

provider "aws" {
  profile = "default"
  region  = local.region
}

###########
### VPC ###
###########

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${var.environment}"
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b"]

  # Not using private subnets in dev to not have to run a NAT Gateway
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]
  private_subnets  = []
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  create_database_subnet_group = false

  public_subnet_tags = {
    Name        = "subnet-public-${var.environment}"
    Environment = var.environment
  }

  tags = local.tags
}

############
### ALBs ###
############

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "alb-${var.environment}"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  target_groups        = []
  https_listeners      = []
  https_listener_rules = []

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = local.tags
}

resource "aws_lb_listener" "ssl" {
  load_balancer_arn = module.alb.lb_arn

  port            = "443"
  protocol        = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad Gateway"
      status_code  = "502"
    }
  }
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "alb-security-group-${var.environment}"
  description = "Security group for ALBs"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = local.tags
}
