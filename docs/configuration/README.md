# Configuration Guide

Complete reference for configuring the AWS Serverless Task Manager across all environments.

## 📋 Table of Contents

- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)
- [AWS Configuration](#aws-configuration)
- [Application Configuration](#application-configuration)
- [Security Configuration](#security-configuration)

## Environment Variables

### Quick Reference

See [Environment Variables Reference](ENV_VARS_REFERENCE.md) for complete documentation of all environment variables used across the project.

### Configuration Hierarchy

Variables are loaded in this priority order (highest to lowest):

1. **Environment Variables** - System/shell environment
2. **GitHub Secrets** - CI/CD pipeline secrets
3. **`.env` File** - Local development (not committed)
4. **`.config` File** - Project defaults
5. **Code Defaults** - Fallback values in code

### Loading Environment Variables

#### Automatic Loading (Scripts)

All scripts automatically load from `.env`:

```bash
# Scripts automatically source environment
./scripts/create-admin.sh

# Or explicitly load
source scripts/load-env.sh
./your-command
```

#### Manual Loading

```bash
# Load environment variables
source scripts/load-env.sh

# Verify loaded
echo $AWS_REGION
```

## Configuration Files

### Project Root Configuration

#### `.config`
Project-wide default values (non-sensitive):

```bash
# Project Configuration
PROJECT_NAME=task-manager
DEFAULT_REGION=eu-west-1
DEFAULT_ENVIRONMENT=sandbox

# Version Configuration
TERRAFORM_VERSION=1.5.0
NODE_VERSION=18.x
PYTHON_VERSION=3.11
```

**Purpose**: Centralized defaults for all deployment scripts and tools.

#### `.env.template`
Template for environment-specific configuration:

```bash
# AWS Configuration
AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=

# Project Configuration
PROJECT_NAME=task-manager
ENVIRONMENT=sandbox

# Application Configuration
AMPLIFY_APP_ID=
NEXT_PUBLIC_COGNITO_USER_POOL_ID=
NEXT_PUBLIC_COGNITO_CLIENT_ID=
# ... more variables
```

**Usage**:
```bash
# Copy template
cp .env.template .env

# Edit with your values
vim .env
```

### Terraform Configuration

#### `terraform/environments/*.tfvars`
Environment-specific Terraform variables:

**sandbox.tfvars**:
```hcl
environment = "sandbox"
aws_region  = "eu-west-1"

# DynamoDB Configuration
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Lambda Configuration
lambda_memory_size = 512
lambda_timeout     = 30
```

**staging.tfvars**:
```hcl
environment = "staging"
aws_region  = "eu-west-1"

# Higher capacity for staging
dynamodb_billing_mode = "PROVISIONED"
dynamodb_read_capacity  = 10
dynamodb_write_capacity = 10

lambda_memory_size = 1024
lambda_timeout     = 60
```

**production.tfvars**:
```hcl
environment = "production"
aws_region  = "eu-west-1"

# Production capacity
dynamodb_billing_mode = "PROVISIONED"
dynamodb_read_capacity  = 50
dynamodb_write_capacity = 50

lambda_memory_size = 2048
lambda_timeout     = 60

# Enable additional features
enable_backup            = true
enable_deletion_protection = true
enable_encryption        = true
```

### Frontend Configuration

#### `frontend/.env.local`
Next.js environment variables (not committed):

```bash
# Public variables (exposed to browser)
NEXT_PUBLIC_AWS_REGION=eu-west-1
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_COGNITO_USER_POOL_ID=eu-west-1_XXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=xxxxxxxxxxxxx
NEXT_PUBLIC_APPSYNC_URL=https://xxx.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_S3_BUCKET=task-manager-uploads-sandbox

# Private variables (server-side only)
AMPLIFY_APP_ID=d123abc456
```

#### `frontend/lib/amplify-config.ts`
Amplify configuration (uses environment variables):

```typescript
export const amplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID || '',
      userPoolClientId: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID || '',
      // ... more config
    },
  },
  // ... API, Storage config
}
```

### Backend Configuration

#### Lambda Environment Variables

Set via Terraform in `terraform/modules/lambda/main.tf`:

```hcl
resource "aws_lambda_function" "this" {
  # ...
  
  environment {
    variables = {
      AWS_REGION           = var.aws_region
      DYNAMODB_TABLE       = var.dynamodb_table_name
      COGNITO_USER_POOL_ID = var.cognito_user_pool_id
      S3_BUCKET            = var.s3_bucket_name
      SES_FROM_EMAIL       = var.ses_from_email
      ENVIRONMENT          = var.environment
    }
  }
}
```

## AWS Configuration

### AWS CLI Configuration

```bash
# Configure AWS CLI
aws configure

# Verify configuration
aws sts get-caller-identity

# List available profiles
aws configure list-profiles

# Use specific profile
export AWS_PROFILE=my-profile
```

### AWS Credentials

**For Local Development** (`.aws/credentials`):
```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

[task-manager-sandbox]
aws_access_key_id = SANDBOX_KEY
aws_secret_access_key = SANDBOX_SECRET

[task-manager-production]
aws_access_key_id = PROD_KEY
aws_secret_access_key = PROD_SECRET
```

**For CI/CD**: Use OIDC (no long-lived credentials):
```yaml
# GitHub Actions
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
```

### Terraform Backend Configuration

```hcl
# terraform/backend.tf
terraform {
  backend "s3" {
    bucket         = "task-manager-terraform-state"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "task-manager-terraform-locks"
    encrypt        = true
  }
}
```

## Application Configuration

### Cognito Configuration

Managed by Terraform, accessed via environment variables:

```bash
# User Pool ID
COGNITO_USER_POOL_ID=eu-west-1_AbCdEf123

# App Client ID
COGNITO_CLIENT_ID=1234567890abcdefghij

# Identity Pool ID (for AWS credentials)
IDENTITY_POOL_ID=eu-west-1:12345678-1234-1234-1234-123456789012
```

### DynamoDB Configuration

```bash
# Table name
DYNAMODB_TABLE=task-manager-sandbox-main

# Access patterns optimized for:
# - Tasks by user
# - Tasks by project
# - Tasks by sprint
# - User management
```

See [DynamoDB Access Patterns](../architecture/06-dynamodb-access-patterns.md) for details.

### S3 Configuration

```bash
# File uploads bucket
S3_BUCKET=task-manager-uploads-sandbox

# Terraform state bucket
TF_STATE_BUCKET=task-manager-terraform-state
```

### SES Configuration

```bash
# Sender email (must be verified)
SES_FROM_EMAIL=noreply@example.com

# Email notification settings
SES_REGION=eu-west-1
```

Verify email:
```bash
./scripts/verify-ses-email.sh
```

### AppSync Configuration

```bash
# GraphQL endpoint
APPSYNC_URL=https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql

# API Key (if using API key auth)
APPSYNC_API_KEY=da2-xxxxxxxxxxxxxxxxxxxx
```

## Security Configuration

### Secrets Management

#### For Local Development
- Store in `.env` (never commit)
- Use AWS Secrets Manager for sensitive values

#### For CI/CD
- Store in GitHub Secrets
- Access via `${{ secrets.SECRET_NAME }}`

#### For Lambda Functions
- Use environment variables (encrypted at rest)
- Use AWS Secrets Manager for highly sensitive data

### IAM Roles and Permissions

**Lambda Execution Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/task-manager-*"
    }
  ]
}
```

**GitHub Actions Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

### Encryption

- **DynamoDB**: Encryption at rest enabled
- **S3**: Server-side encryption (SSE-S3)
- **Secrets**: AWS Secrets Manager with KMS
- **Terraform State**: Encrypted in S3

## Configuration Best Practices

### ✅ Do's

- ✅ Use environment variables for all configuration
- ✅ Keep `.env` file out of version control
- ✅ Use separate configurations per environment
- ✅ Validate configuration before deployment
- ✅ Document all environment variables
- ✅ Use OIDC for CI/CD authentication
- ✅ Encrypt sensitive data at rest

### ❌ Don'ts

- ❌ Hardcode credentials in code
- ❌ Commit `.env` files to git
- ❌ Use same configuration for all environments
- ❌ Store secrets in plain text
- ❌ Use long-lived AWS access keys in CI/CD
- ❌ Share production credentials

## Validation

### Check Current Configuration

```bash
# Display current environment
./scripts/load-env.sh
env | grep -E "AWS_|NEXT_PUBLIC_|COGNITO_"

# Verify Terraform configuration
cd terraform
terraform validate

# Check required variables
./scripts/verify-config.sh
```

### Update Configuration

```bash
# Update from Terraform outputs
./scripts/update-amplify-env.sh --environment sandbox

# Manually update
vim .env

# Reload environment
source scripts/load-env.sh
```

## Troubleshooting

### Configuration Not Loading
- Verify `.env` file exists
- Check file permissions
- Source `load-env.sh` script
- Verify variable names (case-sensitive)

### AWS Credentials Issues
- Run `aws configure` to set up
- Check `aws sts get-caller-identity`
- Verify IAM permissions
- Check region is correct

### Environment Mismatch
- Verify `ENVIRONMENT` variable
- Check Terraform workspace
- Confirm GitHub environment settings

---

**Related Documentation**:
- [Environment Variables Reference](ENV_VARS_REFERENCE.md) - Complete variable list
- [Security Guide](../security/README.md) - Security best practices
- [Deployment Guide](../deployment/README.md) - Deployment configuration

**Last Updated**: February 2026
