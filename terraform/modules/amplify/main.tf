# ============================================================================
# GITHUB INTEGRATION
# ============================================================================
# SECURITY NOTE: GitHub token should be configured via AWS Console or CLI
# using GitHub App integration, NOT via Terraform access_token parameter.
# Using access_token stores the token in Terraform state (security risk).
#
# To connect repository:
#   1. Go to Amplify Console → App Settings → General → Edit
#   2. Connect via GitHub App (OAuth)
#   OR
#   3. Use AWS CLI: aws amplify update-app --app-id <id> --access-token <token>
#
# If you must use Secrets Manager for initial setup, configure outside Terraform.

# ============================================================================
# AWS AMPLIFY APP FOR FRONTEND DEPLOYMENT
# ============================================================================

resource "aws_amplify_app" "frontend" {
  name        = var.app_name
  repository  = var.repository_url
  description = "Task Manager Frontend Application"
  platform    = "WEB"

  # NOTE: app_root configuration for monorepo SSR detection must be set via:
  # 1. AWS Console: App Settings → General → Edit → Monorepo settings
  # 2. AWS CLI: aws amplify update-app --app-id <id> --app-root frontend
  # Terraform aws_amplify_app doesn't support app_root parameter yet.

  # Build settings from amplify.yml in repo root
  build_spec = file("${path.root}/../amplify.yml")

  # Environment variables for Next.js runtime
  environment_variables = {
    NEXT_PUBLIC_COGNITO_USER_POOL_ID        = var.cognito_user_pool_id
    NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID = var.cognito_client_id
    NEXT_PUBLIC_APPSYNC_URL                 = var.appsync_url
    NEXT_PUBLIC_API_URL                     = var.appsync_url
    NEXT_PUBLIC_AWS_REGION                  = var.aws_region
    NEXT_PUBLIC_S3_BUCKET                   = var.s3_bucket_name
  }

  # Enable auto branch creation for feature branches
  enable_branch_auto_build     = var.enable_auto_build
  enable_branch_auto_deletion  = true
  enable_auto_branch_creation  = false

  # IAM service role for Amplify
  iam_service_role_arn = aws_iam_role.amplify.arn

  # Lifecycle rule to ignore access_token changes
  # This prevents Terraform from trying to manage the GitHub connection
  # after initial setup. Manage via AWS Console or CLI instead.
  lifecycle {
    ignore_changes = [access_token]
  }

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

  # Enable performance optimizations for production SSR
  enable_performance_mode = var.environment == "staging" ? false : true

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

  # Minimal permissions for Amplify Hosting (CloudWatch Logs only)
  # Amplify service handles build/deploy internally - no need for amplify:* permissions
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
