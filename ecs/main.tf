provider "aws" {
  profile = "default"
  region  = local.region
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name = "ecs-${terraform.workspace}"

  container_insights = local.env.production

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy = [
    {
      capacity_provider = local.env.default_capacity_provider
    }
  ]

  tags = local.tags
}


resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-${terraform.workspace}"
  path = "/"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

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