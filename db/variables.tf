locals {
  region = "eu-central-1"

  env = yamldecode(file("./env/${terraform.workspace}/env.yaml"))

  tags = {
    Environment = terraform.workspace
  }
}


variable "apply_immediately" {
  description = "Set to true if apply changes immediately instead of a during a maintenance window"
  type = bool
  default = false
}