output "ecs_execution_role_arn" {
  value       = aws_iam_role.ecs_execution_role.arn
  description = "ECS Task Execution Role ARN"
}

output "ecs_task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS Task Role ARN"
}

output "github_oidc_role_arn" {
  value       = aws_iam_role.github_actions_oidc.arn
  description = "GitHub Actions OIDC Role ARN"
}
