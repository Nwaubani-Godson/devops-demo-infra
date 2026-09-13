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

# 3. IAM OpenID Connect Provider for GitHub Actions (Creates OIDC Provider in AWS)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a21d286dd773791732c0c71801b972d56cf1"]
}

# ==============================================================================
# LEAST PRIVILEGE ROLE 1: App Repository CI Role (devops-demo-app)
# Scope: ECR Auth Token & Image Push strictly for devops-demo-app repository
# ==============================================================================
resource "aws_iam_role" "app_github_actions" {
  name = "devops-demo-app-ecr-role"

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
          "ForAnyValue:StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Nwaubani-Godson/devops-demo-app:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_ecr_policy" {
  name        = "devops-demo-app-ecr-policy"
  description = "Least-privilege policy allowing image push to devops-demo-app ECR repo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:*:*:repository/devops-demo-app"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app_ecr_attach" {
  role       = aws_iam_role.app_github_actions.name
  policy_arn = aws_iam_policy.app_ecr_policy.arn
}

# ==============================================================================
# LEAST PRIVILEGE ROLE 2: Infrastructure Repository Role (devops-demo-infra)
# Scope: Scoped to S3 backend, DynamoDB locks, VPC/EC2, ALB, ECS, ECR, CloudWatch
# ==============================================================================
resource "aws_iam_role" "infra_github_actions" {
  name = "devops-demo-infra-tf-role"

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
          "ForAnyValue:StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Nwaubani-Godson/devops-demo-infra:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "infra_tf_policy" {
  name        = "devops-demo-infra-tf-policy"
  description = "Least-privilege policy for devops-demo-infra Terraform execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::devops-demo-tfstate-nwaubani-godson",
          "arn:aws:s3:::devops-demo-tfstate-nwaubani-godson/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/devops-demo-tflocks"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "elasticloadbalancing:*",
          "logs:*",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infra_tf_attach" {
  role       = aws_iam_role.infra_github_actions.name
  policy_arn = aws_iam_policy.infra_tf_policy.arn
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

output "app_github_role_arn" {
  value       = aws_iam_role.app_github_actions.arn
  description = "Least privilege IAM Role ARN for devops-demo-app ECR push"
}

output "infra_github_role_arn" {
  value       = aws_iam_role.infra_github_actions.arn
  description = "Least privilege IAM Role ARN for devops-demo-infra Terraform deployment"
}
