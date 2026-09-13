variable "repository_name" {
  type        = string
  default     = "devops-demo-app"
  description = "ECR Repository Name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}
