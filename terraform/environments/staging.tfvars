# Staging Environment Configuration

environment  = "staging"
project_name = "task-manager"
aws_region   = "eu-west-1"
owner        = "devops-team"
cost_center  = "engineering"

# Cognito Configuration
allowed_email_domains = ["amalitech.com", "amalitechtraining.org"]
cognito_callback_urls = [
  "https://staging.task-manager.amplifyapp.com/auth/callback"
]
cognito_logout_urls = [
  "https://staging.task-manager.amplifyapp.com"
]

# Lambda Configuration
lambda_runtime     = "nodejs18.x"
lambda_timeout     = 30
lambda_memory_size = 1024

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Notification Configuration
notification_emails = [] # Add admin emails here

# Tags
tags = {
  Environment = "staging"
  Project     = "task-manager"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
