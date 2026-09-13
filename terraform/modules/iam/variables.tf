variable "environment" {
  type        = string
  description = "Environment name"
}

variable "github_repo" {
  type        = string
  default     = "*/*"
  description = "GitHub repository formatted as owner/repo"
}
