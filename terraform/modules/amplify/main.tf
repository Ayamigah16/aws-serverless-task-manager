# ============================================================================
# SECRETS MANAGER - GITHUB TOKEN REFERENCE
# ============================================================================
# Secret must be created externally using scripts/create-github-secret.sh
# This keeps the token completely out of Terraform state and files

data "aws_secretsmanager_secret" "github_token" {
  name = var.github_secret_name
}

data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

# ============================================================================
# AWS AMPLIFY APP FOR FRONTEND DEPLOYMENT
# ============================================================================

resource "aws_amplify_app" "frontend" {
  name        = var.app_name
  repository  = var.repository_url
  description = "Task Manager Frontend Application"
  platform    = "WEB_COMPUTE"

  # OAuth token for GitHub/GitLab/Bitbucket - reads from Secrets Manager
  access_token = data.aws_secretsmanager_secret_version.github_token.secret_string

  # Build settings from amplify.yml in repo root
  build_spec = file("${path.root}/../amplify.yml")

  # Environment variables for Next.js
  environment_variables = {
    NEXT_PUBLIC_COGNITO_USER_POOL_ID        = var.cognito_user_pool_id
    NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID = var.cognito_client_id
    NEXT_PUBLIC_APPSYNC_URL                 = var.appsync_url
    NEXT_PUBLIC_API_URL                     = var.appsync_url
    NEXT_PUBLIC_AWS_REGION                  = var.aws_region
    NEXT_PUBLIC_S3_BUCKET                   = var.s3_bucket_name
    _LIVE_UPDATES                           = jsonencode([{
      pkg     = "@aws-amplify/cli"
      type    = "npm"
      version = "latest"
    }])
  }

  # Enable auto branch creation for feature branches
  enable_branch_auto_build     = var.enable_auto_build
  enable_branch_auto_deletion  = true
  enable_auto_branch_creation  = false

  # IAM service role for Amplify
  iam_service_role_arn = aws_iam_role.amplify.arn

  tags = merge(
    var.tags,
    {
      Environment = var.environment
      Application = "TaskManager"
      ManagedBy   = "Terraform"
    }
  )
}

# Main branch deployment
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.main_branch_name

  # Default to PRODUCTION for main branch accessibility
  # Use BETA for staging, DEVELOPMENT only for feature branches
  stage = var.environment == "staging" ? "BETA" : "PRODUCTION"

  enable_auto_build           = true
  enable_pull_request_preview = var.enable_pr_preview

  # Override environment variables for this branch if needed
  environment_variables = {}

  tags = var.tags
}

# Development branch deployment (if different from main)
resource "aws_amplify_branch" "dev" {
  count = var.dev_branch_name != var.main_branch_name ? 1 : 0

  app_id      = aws_amplify_app.frontend.id
  branch_name = var.dev_branch_name

  stage                       = "DEVELOPMENT"
  enable_auto_build           = true
  enable_pull_request_preview = true

  tags = var.tags
}

# Custom domain (optional)
resource "aws_amplify_domain_association" "main" {
  count = var.custom_domain != "" ? 1 : 0

  app_id      = aws_amplify_app.frontend.id
  domain_name = var.custom_domain

  # Main branch subdomain
  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = var.environment == "production" ? "" : var.environment
  }

  # Development branch subdomain
  dynamic "sub_domain" {
    for_each = var.dev_branch_name != var.main_branch_name ? [1] : []
    content {
      branch_name = aws_amplify_branch.dev[0].branch_name
      prefix      = "dev"
    }
  }

  wait_for_verification = false
}

# ============================================================================
# IAM ROLE FOR AMPLIFY
# ============================================================================

resource "aws_iam_role" "amplify" {
  name = "${var.app_name}-amplify-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "amplify.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "amplify" {
  name = "${var.app_name}-amplify-policy"
  role = aws_iam_role.amplify.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "amplify:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# WEBHOOK FOR MANUAL DEPLOYMENTS (OPTIONAL)
# ============================================================================

resource "aws_amplify_webhook" "main" {
  count = var.enable_webhook ? 1 : 0

  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Webhook for manual deployments"
}
