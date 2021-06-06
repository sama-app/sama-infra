locals {
  name = "sama"
  environment = "dev"
  region = "eu-central-1"
  certificate_arn = "arn:aws:acm:eu-central-1:216862985054:certificate/4c6718d1-dcf4-49a8-9643-2da901c1fc35"
  ami_id = "ami-0122f4f4a505d7d7e"
  key_name = "sama-dev"

  tags = {
    Environment = local.environment
  }
}

provider "aws" {
  profile = "default"
  region = local.region
}

###########
### VPC ###
###########

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-dev"
  cidr = "10.0.0.0/16"

  azs = ["eu-central-1a", "eu-central-1b"]

  # Not using private subnets in dev to not have to run a NAT Gateway
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  create_database_subnet_group = false

  public_subnet_tags = {
    Name = "subnet-public-dev"
    Environment = "dev"
  }

  tags = local.tags
}


###########
### RDS ###
###########

module "db" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-${local.environment}"

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
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.rds_sg.security_group_id]

  performance_insights_enabled = false
  create_monitoring_role       = false

  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = local.tags
}

module "rds_sg" {
  source  = "terraform-aws-modules/security-group/aws"

  name        = "rds-security-group-dev"
  description = "Security group for PostgreSQL RDS in dev"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]


  tags = local.tags
}

############
### ALBs ###
############

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name = "alb-dev"

  load_balancer_type = "application"

  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.public_subnets
  security_groups = [module.alb_sg.security_group_id]

  target_groups = [
    {
      name = "alb-green-tg-dev"
      backend_protocol = "HTTP"
      backend_port = 3000
      deregistration_delay = 30
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 15
        path                = "/__mon/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 5
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-299"
      }
    },
    {
      name = "alb-blue-tg-dev"
      backend_protocol = "HTTP"
      backend_port = 3000
      deregistration_delay = 30
      target_type = "instance"
      health_check = {
        enabled             = true
        interval            = 7
        path                = "/__mon/health"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200-299"
      }
    }
  ]

  https_listeners = []

  https_listener_rules = []

  http_tcp_listeners = [
    {
      port = 80
      protocol = "HTTP"
      action_type = "redirect"
      redirect = {
        port = "443"
        protocol = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = local.tags
}

resource "aws_lb_listener" "sama_service" {
  load_balancer_arn = module.alb.lb_arn

  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = module.alb.target_group_arns[0]
        weight = var.enable_green_env ? 100 : 0
      }
      target_group {
        arn = module.alb.target_group_arns[1]
        weight = var.enable_blue_env ? 100 : 0
      }
      stickiness {
        enabled = false
        duration = 1
      }
    }
  }
}

module "alb_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name = "alb-security-group-dev"
  description = "Security group for ALBs in dev"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules = ["http-80-tcp", "https-443-tcp"]

  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = local.tags
}

############
### ASGs ###
############


resource "aws_autoscaling_group" "green" {
  name = "asg-green-dev"

  desired_capacity          = var.enable_green_env ? var.green_instance_count : 0
  min_size                  = 0
  max_size                  = 4
  vpc_zone_identifier       = module.vpc.public_subnets
  target_group_arns = [module.alb.target_group_arns[0]]

  health_check_grace_period = 15
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.sama_service.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "blue" {
  name = "asg-blue-dev"

  desired_capacity          = var.enable_blue_env ? var.blue_instance_count : 0
  min_size                  = 0
  max_size                  = 4
  vpc_zone_identifier       = module.vpc.public_subnets
  target_group_arns = [module.alb.target_group_arns[1]]

  health_check_grace_period = 15
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.sama_service.id
    version = "$Latest"
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }
}

resource "aws_launch_template" "sama_service" {
  name = "lt-dev"
  image_id = local.ami_id
  instance_type = "t2.micro"
  key_name = local.key_name
  update_default_version = true

  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile {
    name = aws_iam_instance_profile.sama_service_asg.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [module.asg_sg.security_group_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Environment = "dev"
      Name = "sama-service-dev"
    }
  }

  user_data = filebase64("${path.module}/deploy.sh")
}

module "asg_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name = "asg-security-group-dev"
  description = "Security group for ASGs in dev"
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
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

  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.tags
}


resource "aws_iam_instance_profile" "sama_service_asg" {
  name = "asg-instance-profile-dev"
  role = aws_iam_role.sama_service_asg.name
}

resource "aws_iam_role" "sama_service_asg" {
  name = "asg-role-dev"
  path = "/"

  managed_policy_arns = [
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
