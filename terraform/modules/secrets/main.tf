# ============================================================================
# AWS SECRETS MANAGER - GITHUB ACCESS TOKEN
# ============================================================================

resource "aws_secretsmanager_secret" "github_token" {
  count = var.create_github_token_secret ? 1 : 0

  name_prefix             = "${var.name_prefix}-github-token-"
  description             = "GitHub Personal Access Token for Amplify deployments"
  recovery_window_in_days = var.secret_recovery_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-github-token"
      Purpose     = "Amplify Git Integration"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )
}

resource "aws_secretsmanager_secret_version" "github_token" {
  count = var.create_github_token_secret && var.github_token_value != "" ? 1 : 0

  secret_id     = aws_secretsmanager_secret.github_token[0].id
  secret_string = var.github_token_value
}

# Data source to retrieve existing secret if not creating new one
data "aws_secretsmanager_secret" "github_token" {
  count = var.create_github_token_secret ? 0 : 1
  name  = var.existing_secret_name
}

data "aws_secretsmanager_secret_version" "github_token" {
  count     = var.create_github_token_secret ? 0 : 1
  secret_id = data.aws_secretsmanager_secret.github_token[0].id
}

# ============================================================================
# OUTPUTS
# ============================================================================

locals {
  secret_arn = var.create_github_token_secret ? aws_secretsmanager_secret.github_token[0].arn : data.aws_secretsmanager_secret.github_token[0].arn
  secret_value = var.create_github_token_secret && var.github_token_value != "" ? var.github_token_value : (
    var.create_github_token_secret ? "" : data.aws_secretsmanager_secret_version.github_token[0].secret_string
  )
}
