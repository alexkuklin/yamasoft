# 1. Provider and Terraform Block
# ------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use a compatible AWS provider version
    }
  }
}

provider "aws" {
  # The region for which the OIDC provider and IAM role will be created.
  # This can be overridden via a variable or a provider block alias if needed.
  region = var.aws_region 
}

# 2. Variables for GitHub/AWS Configuration
# ------------------------------------------------------------------
variable "github_org" {
  description = "Your GitHub Organization name (e.g., 'my-org')"
  type        = string
}

variable "github_repo" {
  description = "Your GitHub Repository name (e.g., 'my-repo')"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource creation"
  type        = string
  default     = "us-east-1"
}

# 3. AWS IAM OIDC Provider for GitHub Actions
# ------------------------------------------------------------------
# This resource tells AWS to trust tokens issued by GitHub's OIDC endpoint.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  # The audience claim from the GitHub token. sts.amazonaws.com is standard for AWS.
  client_id_list = [
    "sts.amazonaws.com"
  ]

  # The list of server certificate thumbprints for the provider's server certificate.
  # This thumbprint is for token.actions.githubusercontent.com and is generally stable.
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" 
  ]
}

# 4. Define the Trust Policy Document for the IAM Role
# ------------------------------------------------------------------
# This document defines the conditions under which the IAM role can be assumed.
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    # Action that allows assuming the role with a web identity token
    actions = ["sts:AssumeRoleWithWebIdentity"]

    # The principal is the OIDC provider we just created
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    # Condition 1: Check the audience is sts.amazonaws.com
    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.github_actions.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Condition 2: Check the 'sub' (subject) claim to ensure it's from the correct repo
    condition {
      test     = "StringLike"
      variable = "${aws_iam_openid_connect_provider.github_actions.url}:sub"
      # This format restricts the role assumption to any branch (*) in the specified repository.
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

# 5. Create the IAM Role for GitHub Actions to assume
# ------------------------------------------------------------------
resource "aws_iam_role" "github_actions_role" {
  name               = "github-actions-oidc-role-${var.github_repo}"
  description        = "IAM role for GitHub Actions to assume for AWS deployments"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  max_session_duration = 3600 # 1 hour max session
}

# 6. Attach an IAM Policy (Example: Read-Only Access)
# ------------------------------------------------------------------
# IMPORTANT: Replace this with the actual minimum necessary permissions for your CI/CD job.
resource "aws_iam_policy" "example_read_only_policy" {
  name        = "github-actions-read-only-policy-${var.github_repo}"
  description = "Example policy for read-only access for GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:ListAllMyBuckets",
          "iam:ListRoles"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_policy_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.example_read_only_policy.arn
}

# 7. Output the Role ARN
# ------------------------------------------------------------------
output "github_actions_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to assume"
  value       = aws_iam_role.github_actions_role.arn
}


variable "cluster_name" {
  type        = string
  default     = "test"
}
