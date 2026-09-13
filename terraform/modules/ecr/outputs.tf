output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "ECR Repository URL"
}

output "repository_arn" {
  value       = aws_ecr_repository.app.arn
  description = "ECR Repository ARN"
}
