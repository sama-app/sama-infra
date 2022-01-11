locals {
  region = "eu-central-1"

  env = yamldecode(file("./env/${terraform.workspace}/env.yaml"))

  tags = {
    Environment = terraform.workspace
    Type        = "bastion"
  }
}

###################
### Environment ###
###################

variable "ami_id" {
  type    = string
  default = "ami-05f7491af5eef733a" # Basic Ubuntu Server
}
