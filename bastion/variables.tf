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
  default = "ami-05f7491af5eef733a" # Basic Ubuntu Server
}
