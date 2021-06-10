locals {
  region = "eu-central-1"

  tags = {
    Environment = var.environment
  }
}

provider "aws" {
  profile = "default"
  region = local.region
}

resource "aws_s3_bucket" "cloudwatch_logs" {
  bucket = "cloudwatch-logs-sama"
  acl = "private"
}

resource "aws_s3_bucket_object" "log_config" {
  bucket = aws_s3_bucket.cloudwatch_logs.id
  key = "awslogs.conf"
  source = "${path.module}/awslogs.conf"
  etag = filemd5("${path.module}/awslogs.conf")
}