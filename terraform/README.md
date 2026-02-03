# Terraform Infrastructure

## Overview

This directory contains Terraform configuration for the serverless task management system.

## Structure

```
terraform/
├── backend.tf          # Remote state configuration
├── provider.tf         # AWS provider configuration
├── main.tf            # Main module orchestration
├── variables.tf       # Input variables
├── outputs.tf         # Output values
├── terraform.tfvars   # Variable values (DO NOT COMMIT)
└── modules/
    ├── cognito/       # User authentication
    ├── dynamodb/      # Database
    ├── lambda/        # Compute functions
    ├── api-gateway/   # REST API
    ├── eventbridge/   # Event bus
    └── ses/           # Email service
```

## Quick Start

### 1. Set up remote state
```bash
../scripts/setup-remote-state.sh
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Plan changes
```bash
terraform plan
```

### 4. Apply configuration
```bash
terraform apply
```

## Modules

### Cognito
- User Pool with email verification
- User Pool Client for OAuth
- Cognito Groups (Admins, Members)
- Pre Sign-Up Lambda trigger

### DynamoDB
- Single table design
- 2 Global Secondary Indexes
- Point-in-time recovery enabled
- Encryption at rest

### Lambda
- Pre Sign-Up trigger
- Task API handler
- Notification handler
- IAM roles with least privilege

### API Gateway
- REST API with Cognito authorizer
- Throttling configured
- CloudWatch logging
- X-Ray tracing

### EventBridge
- Custom event bus
- 3 event rules (TaskAssigned, TaskStatusUpdated, TaskClosed)
- Lambda targets

### SES
- Email identity verification
- Configuration set

## Variables

Key variables in `terraform.tfvars`:
- `admin_email`: Admin user email
- `ses_sender_email`: SES verified sender
- `aws_region`: AWS region (default: us-east-1)

## Outputs

After deployment, get outputs:
```bash
terraform output
```

Outputs include:
- Cognito User Pool ID
- API Gateway URL
- DynamoDB table name
- EventBridge bus name

## State Management

State is stored remotely in:
- S3 bucket: `task-manager-terraform-state`
- DynamoDB lock table: `task-manager-terraform-locks`

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will delete all data!
