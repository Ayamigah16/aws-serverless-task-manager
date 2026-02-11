# AWS Configuration
aws_region  = "eu-west-1"
environment = "sandbox"

# Project Configuration
project_name = "task-manager"
owner        = "devops-team"
cost_center  = "engineering"

# IMPORTANT: Set these values before deployment
admin_email      = "admin@amalitech.com"
ses_sender_email = "noreply@amalitech.com"

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
