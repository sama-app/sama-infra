output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "The IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "lb_arn" {
  description = "The ARN of the main load balancer"
  value       = module.alb.lb_arn
}