locals {
  region                 = "eu-central-1"
  sama_web_origin_id     = "sama-web-${terraform.workspace}"
  sama_service_origin_id = "sama-app-${terraform.workspace}"

  env = yamldecode(file("./env/${terraform.workspace}/env.yaml"))

  tags = {
    Environment = terraform.workspace
  }
}