###################
### Environment ###
###################

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "key_name" {
  type    = string
  default = "sama-dev"
}

variable "ami_id" {
  type    = string
  default = "ami-0d547b7d6e7668b70"
}
