locals {
  region = "eu-central-1"

  env = yamldecode(file("./env/${terraform.workspace}/env.yaml"))

  tags = {
    Environment = terraform.workspace
    Type        = "monitoring"
  }
}

###################
### Environment ###
###################

variable "ami_id" {
  type    = string
  default = "ami-0b93d9e35bfc492f9"
}
