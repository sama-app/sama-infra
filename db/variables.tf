locals {
  region = "eu-central-1"

  tags = {
    Environment = var.environment
  }
}

###################
### Environment ###
###################

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "subnets" {
  type = list(string)
}