variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "sandbox"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "task-manager"
}

variable "owner" {
  description = "Project owner"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "admin_email" {
  description = "Admin email for initial setup"
  type        = string
}

variable "notification_emails" {
  description = "List of admin email addresses to receive all notifications (members auto-subscribe on signup)"
  type        = list(string)
  default     = []
}

variable "allowed_email_domains" {
  description = "Allowed email domains for sign-up"
  type        = list(string)
  default     = ["amalitech.com", "amalitechtraining.org"]
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "nodejs18.x"
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 1000
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 2000
}

variable "cognito_callback_urls" {
  description = "Cognito OAuth callback URLs"
  type        = list(string)
  default     = ["http://localhost:3000", "https://localhost:3000"]
}

variable "cognito_logout_urls" {
  description = "Cognito OAuth logout URLs"
  type        = list(string)
  default     = ["http://localhost:3000", "https://localhost:3000"]
}

# ============================================================================
# AMPLIFY FRONTEND DEPLOYMENT VARIABLES
# ============================================================================

variable "enable_amplify_deployment" {
  description = "Enable AWS Amplify deployment for frontend"
  type        = bool
  default     = false
}

variable "github_repository_url" {
  description = "GitHub repository URL (e.g., https://github.com/username/repo)"
  type        = string
  default     = ""
}

variable "github_secret_name" {
  description = "Name of AWS Secrets Manager secret containing GitHub token (created via scripts/create-github-secret.sh)"
  type        = string
  default     = "task-manager-github-token"
}

variable "github_main_branch" {
  description = "Main branch name for production deployment"
  type        = string
  default     = "main"
}

variable "github_dev_branch" {
  description = "Development branch name"
  type        = string
  default     = "dev"
}

variable "amplify_enable_auto_build" {
  description = "Enable automatic builds on git push"
  type        = bool
  default     = true
}

variable "amplify_enable_pr_preview" {
  description = "Enable pull request preview deployments"
  type        = bool
  default     = false
}

variable "amplify_enable_webhook" {
  description = "Create webhook for manual deployments"
  type        = bool
  default     = false
}

variable "amplify_custom_domain" {
  description = "Custom domain for Amplify app (leave empty for default amplifyapp.com)"
  type        = string
  default     = ""
}
