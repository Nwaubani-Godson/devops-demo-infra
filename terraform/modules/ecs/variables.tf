variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ECS tasks"
}

variable "target_group_arn" {
  type        = string
  description = "ALB Target Group ARN"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB Security Group ID"
}

variable "image_url" {
  type        = string
  description = "Docker Container Image URL in ECR"
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Number of ECS tasks"
}

variable "container_cpu" {
  type        = number
  default     = 256
  description = "Fargate CPU units"
}

variable "container_memory" {
  type        = number
  default     = 512
  description = "Fargate Memory (MB)"
}

variable "execution_role_arn" {
  type        = string
  description = "IAM Task Execution Role ARN"
}

variable "task_role_arn" {
  type        = string
  description = "IAM Task Role ARN"
}
