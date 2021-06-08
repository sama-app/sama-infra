###################
### Environment ###
###################

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "lb_arn" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "key_name" {
  type    = string
  default = "sama-dev"
}

##################
### Deployment ###
##################

variable "ami_id" {
  type    = string
  default = "ami-0122f4f4a505d7d7e"
}

variable "enable_green_env" {
  description = "Enable green environment"
  type        = bool
  default     = true
}

variable "green_instance_count" {
  description = "Number of instances in green environment"
  type        = number
  default     = 1
}

variable "enable_blue_env" {
  description = "Enable blue environment"
  type        = bool
  default     = false
}

variable "blue_instance_count" {
  description = "Number of instances in blue environment"
  type        = number
  default     = 1
}

locals {
  traffic_dist_map = {
    blue = {
      blue  = 100
      green = 0
    }
    green = {
      blue  = 0
      green = 100
    }
  }
}

variable "traffic_distribution" {
  description = "Blue / Green ASGs traffic distribution"
  type        = string
}