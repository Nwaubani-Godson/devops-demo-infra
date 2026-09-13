output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB Public DNS Name"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB Security Group ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.app.arn
  description = "Target Group ARN"
}
