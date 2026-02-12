# Production Environment Configuration

environment  = "production"
project_name = "task-manager"
aws_region   = "eu-west-1"
owner        = "devops-team"
cost_center  = "engineering"

# Cognito Configuration
allowed_email_domains = ["amalitech.com", "amalitechtraining.org"]
cognito_callback_urls = [
  "https://task-manager.amplifyapp.com/auth/callback",
  "https://app.task-manager.com/auth/callback" # Add your custom domain
]
cognito_logout_urls = [
  "https://task-manager.amplifyapp.com",
  "https://app.task-manager.com" # Add your custom domain
]

# Lambda Configuration
lambda_runtime     = "nodejs18.x"
lambda_timeout     = 30
lambda_memory_size = 2048

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST" # or "PROVISIONED" with specified capacity

# Notification Configuration
notification_emails = [] # Add admin emails here

# Tags
tags = {
  Environment = "production"
  Project     = "task-manager"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Owner       = "devops-team"
  Compliance  = "required"
}
