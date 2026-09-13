terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# 1. S3 Bucket for Terraform State
resource "aws_s3_bucket" "tf_state" {
  bucket        = "devops-demo-tfstate-nwaubani-godson"
  force_destroy = false

  tags = {
    Name        = "devops-demo-tfstate"
    Environment = "global"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "tf_locks" {
  name         = "devops-demo-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "devops-demo-tflocks"
    Environment = "global"
    ManagedBy   = "Terraform"
  }
}

# 3. OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# 4. IAM Role for GitHub Actions 
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsRole-DevOpsDemo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Nwaubani-Godson/devops-demo-infra:*",
              "repo:Nwaubani-Godson/devops-demo-app:*",
              "repo:nwaubani-godson/devops-demo-infra:*",
              "repo:nwaubani-godson/devops-demo-app:*"
            ]
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# 5. Policy Attachment for Infrastructure Orchestration 
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Outputs
output "s3_bucket_name" {
  value       = aws_s3_bucket.tf_state.id
  description = "S3 Bucket Name for Terraform Remote State"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.tf_locks.id
  description = "DynamoDB Table Name for State Locking"
}

output "github_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM Role ARN for GitHub Actions (arn:aws:iam::654654484434:role/GitHubActionsRole-DevOpsDemo)"
}
