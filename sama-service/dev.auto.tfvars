environment = "dev"

vpc_id         = "vpc-016aad6a1a3fd88cf"
public_subnets = ["subnet-0d32617a1bd265b95", "subnet-08ac263cc0c45fed6"]
secret_manager_secret_arn = "arn:aws:secretsmanager:eu-central-1:216862985054:secret:secret/sama-service_dev-F3IjDc"

lb_arn          = "arn:aws:elasticloadbalancing:eu-central-1:216862985054:loadbalancer/app/alb-dev/bb33b81f806004ec"
certificate_arn = "arn:aws:acm:eu-central-1:216862985054:certificate/4c6718d1-dcf4-49a8-9643-2da901c1fc35"
