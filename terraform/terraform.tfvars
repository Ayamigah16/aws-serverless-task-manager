# AWS Configuration
aws_region  = "eu-west-1"
environment = "sandbox"

# Project Configuration
project_name = "task-manager"
owner        = "devops-team"
cost_center  = "engineering"

# IMPORTANT: Set these values before deployment
admin_email         = "admin@amalitech.com"
notification_emails = ["admin@amalitech.com"] # Optional: Admins who receive all notifications. Members auto-subscribe on signup.

# Email Domain Restrictions
allowed_email_domains = ["amalitech.com", "amalitechtraining.org"]

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# API Gateway Configuration
api_throttle_rate_limit  = 1000
api_throttle_burst_limit = 2000

# Lambda Configuration
lambda_runtime     = "nodejs18.x"
lambda_timeout     = 30
lambda_memory_size = 256

# Cognito Configuration
cognito_callback_urls = [
  "http://localhost:3000",
  "https://main.d3b1h41scgvbsd.amplifyapp.com"
]
cognito_logout_urls = [
  "http://localhost:3000",
  "https://main.d3b1h41scgvbsd.amplifyapp.com"
]

# ============================================================================
# AWS AMPLIFY FRONTEND DEPLOYMENT
# ============================================================================

# Step 1: Create GitHub token secret (run once)
#   ./scripts/create-github-secret.sh
#
# Step 2: Enable Amplify deployment
enable_amplify_deployment = true
github_repository_url     = "https://github.com/Ayamigah16/aws-serverless-task-manager"
github_secret_name        = "task-manager-github-token"  # Name from create-github-secret.sh
github_main_branch        = "main"
github_dev_branch         = "dev"
#
# How it works:
# - First run: Terraform stores token in AWS Secrets Manager
# - Subsequent runs: Token is read from Secrets Manager
# - To rotate: Update token value and run terraform apply again
#
# Create GitHub token: https://github.com/settings/tokens
# Required scope: 'repo'

# Optional Amplify settings:
# amplify_enable_auto_build = true
# amplify_enable_pr_preview = false
# amplify_custom_domain     = "" # e.g., "taskmanager.example.com"
