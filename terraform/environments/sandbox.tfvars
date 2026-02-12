# Sandbox Environment Configuration

environment  = "sandbox"
project_name = "task-manager"
aws_region   = "eu-west-1"
owner        = "devops-team"
cost_center  = "engineering"

# Cognito Configuration
allowed_email_domains = ["amalitech.com", "amalitechtraining.org"]
cognito_callback_urls = [
  "http://localhost:3000/auth/callback",
  "https://sandbox.task-manager.amplifyapp.com/auth/callback"
]
cognito_logout_urls = [
  "http://localhost:3000",
  "https://sandbox.task-manager.amplifyapp.com"
]

# Lambda Configuration
lambda_runtime     = "nodejs18.x"
lambda_timeout     = 30
lambda_memory_size = 512

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Notification Configuration
notification_emails = [] # Add admin emails here

# Tags
tags = {
  Environment = "sandbox"
  Project     = "task-manager"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Owner       = "devops-team"
}
