resource "aws_iam_role" "ci-role" {
  name = "ci-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:Davidcode2/blog:ref:refs/heads/main",
              "repo:Davidcode2/immoly:ref:refs/heads/main"
            ]
          },
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ci-policy" {
  name = "ci-policy"
  role = aws_iam_role.ci-role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/ssh/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/compute/*",
          "arn:aws:ssm:eu-central-1:${var.aws_account_id}:parameter/immoly*"
        ]
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
}
