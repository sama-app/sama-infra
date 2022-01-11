provider "aws" {
  profile = "default"
  region  = local.region
}

###########
### ECS ###
###########

data "aws_vpc" "selected" {
  id = local.env.vpc_id
}

data "aws_ecs_cluster" "selected" {
  cluster_name = "ecs-${terraform.workspace}"
}

data "aws_iam_role" "execution" {
  name = "ecs-task-execution-${terraform.workspace}"
}


resource "aws_ecs_task_definition" "prometheus" {
  family = "prometheus-${terraform.workspace}"
  cpu    = 256
  memory = 512

  execution_role_arn = data.aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.prometheus.arn
  network_mode       = "awsvpc"

  volume {
    name = "config"
  }

  container_definitions = jsonencode([
    {
      name      = "prometheus"
      image     = "216862985054.dkr.ecr.eu-central-1.amazonaws.com/prometheus:latest"
      essential = true
      portMappings = [
        {
          containerPort = 9090
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "config"
          containerPath = "/output"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group : "prometheus-${terraform.workspace}"
          awslogs-region : "eu-central-1"
          awslogs-stream-prefix : "prometheus-ecs"
        }
      }
    },
    {
      name      = "prometheus-ecs-discovery"
      image     = "tkgregory/prometheus-ecs-discovery:latest"
      essential = true
      command   = ["-config.write-to=/output/ecs_file_sd.yml"]
      mountPoints = [
        {
          sourceVolume  = "config"
          containerPath = "/output"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group : "prometheus-${terraform.workspace}"
          awslogs-region : "eu-central-1"
          awslogs-stream-prefix : "prometheus-ecs-discovery"
        }
      }
    }
  ])

  requires_compatibilities = ["FARGATE"]

  tags = local.tags
}


resource "aws_ecs_service" "prometheus" {
  name            = "prometheus"
  cluster         = data.aws_ecs_cluster.selected.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  depends_on      = [aws_iam_policy.prometheus]
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.env.subnets
    security_groups  = [module.security_group.security_group_id]
    assign_public_ip = true # required when using a public subnet
  }

  tags = local.tags
}

module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "prometheus-ecs-sg-${terraform.workspace}"
  description = "Security group for prometheus ECS"
  vpc_id      = data.aws_vpc.selected.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "TCP"
      description = "application port"
      cidr_blocks = data.aws_vpc.selected.cidr_block
    }
  ]

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

###########
### IAM ###
###########
resource "aws_iam_role" "prometheus" {
  name = "prometheus-ecs-${terraform.workspace}"
  path = "/"

  managed_policy_arns = [aws_iam_policy.prometheus.arn]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "prometheus" {
  name = "prometheus-ecs-${terraform.workspace}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "ecs:ListClusters",
          "ecs:ListTasks",
          "ecs:DescribeTask",
          "ec2:DescribeInstances",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTasks",
          "ecs:DescribeTaskDefinition"
        ],
        Resource : ["*"]
      }
    ]
  })
}


