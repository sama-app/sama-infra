output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "The IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "The IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "The IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "lb_arn" {
  description = "The ARN of the main load balancer"
  value       = module.alb.lb_arn
}

output "lb_https_listener_arn" {
  description = "The ARN of HTTPs listener of the main load valancer"
  value       = aws_lb_listener.ssl.arn
}