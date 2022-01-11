provider "aws" {
  profile = "default"
  region  = local.region
}

###########
### VPC ###
###########

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-${terraform.workspace}"
  cidr = local.env.vpc.cidr

  azs = ["eu-central-1a", "eu-central-1b"]

  # Not using private subnets in dev to not have to run a NAT Gateway
  public_subnets   = local.env.vpc.subnets.public
  private_subnets  = local.env.vpc.subnets.private
  database_subnets = local.env.vpc.subnets.db

  enable_nat_gateway = local.env.vpc.nat_gateway_enabled
  enable_vpn_gateway = false

  create_database_subnet_group = false

  public_subnet_tags = {
    Environment = terraform.workspace
  }

  private_subnet_tags = {
    Environment = terraform.workspace
  }

  database_subnet_tags = {
    Environment = terraform.workspace
  }

  tags = local.tags
}

############
### ALBs ###
############

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "alb-${terraform.workspace}"

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
  certificate_arn = local.env.certificate_arn

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

  name        = "alb-security-group-${terraform.workspace}"
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
