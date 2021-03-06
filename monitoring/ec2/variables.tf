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
  default = "ami-00b6106073860d6ac"
}
