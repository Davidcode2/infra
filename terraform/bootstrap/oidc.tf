# GitHub Actions OIDC Authentication
# This allows GitHub Actions to authenticate to AWS without long-lived credentials

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  # GitHub's thumbprints (verified from GitHub documentation)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
  
  tags = {
    Name        = "GitHub Actions OIDC Provider"
    Environment = "Infrastructure"
    ManagedBy   = "Terraform"
  }
}

# IAM Role for GitHub Actions to assume
resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-infra"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Only allow from Davidcode2/infra repository
          "token.actions.githubusercontent.com:sub" = "repo:Davidcode2/infra:*"
        }
      }
    }]
  })
  
  tags = {
    Name        = "GitHub Actions Terraform Role"
    Environment = "Infrastructure"
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for Terraform operations
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-permissions"
  role = aws_iam_role.github_actions.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 state backend access
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      # DynamoDB state locking
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      # SSM Parameter Store access (read-only)
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/terraform/infra/*"
      },
      # Allow Terraform to manage AWS resources
      # Add specific permissions as needed for your infrastructure
      {
        Effect = "Allow"
        Action = [
          "iam:*",
          "ec2:*",
          "s3:*",
          "dynamodb:*",
          "ssm:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output the role ARN for use in GitHub Actions workflow
output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions to assume"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
