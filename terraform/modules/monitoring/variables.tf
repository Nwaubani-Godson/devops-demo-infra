variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_id" {
  type        = string
  description = "Public Subnet ID to place monitoring EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 Instance Type for Monitoring Host"
}
