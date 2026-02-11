# AWS Configuration
aws_region  = "eu-west-1"
environment = "sandbox"

# Project Configuration
project_name = "task-manager"
owner        = "devops-team"
cost_center  = "engineering"

# IMPORTANT: Set these values before deployment
admin_email         = "admin@amalitech.com"
notification_emails = ["admin@amalitech.com"]  # Optional: Admins who receive all notifications. Members auto-subscribe on signup.

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
cognito_callback_urls = ["http://localhost:3000", "https://main.dieb2ukn8mt87.amplifyapp.com"]
cognito_logout_urls   = ["http://localhost:3000", "https://main.dieb2ukn8mt87.amplifyapp.com"]
