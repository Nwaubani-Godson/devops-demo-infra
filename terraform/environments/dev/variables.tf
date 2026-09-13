variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag for app"
}

variable "desired_count" {
  type    = number
  default = 1
}
