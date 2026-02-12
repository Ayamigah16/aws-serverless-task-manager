# Environment Variables Reference

This document lists all environment variables used across the project for easy reference.

## Core Configuration

### AWS Configuration
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `AWS_REGION` | AWS Region for resources | No | eu-west-1 | All scripts, Lambda functions |
| `AWS_ACCOUNT_ID` | AWS Account ID | Yes (CI/CD) | - | GitHub Actions |
| `AWS_ROLE_ARN` | IAM Role ARN for OIDC | Yes (CI/CD) | - | GitHub Actions |

### Project Configuration
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `PROJECT_NAME` | Project prefix for resources | No | task-manager | Scripts, Terraform |
| `ENVIRONMENT` | Deployment environment | No | sandbox | Scripts, Terraform |

## Frontend Configuration

### Next.js Environment Variables
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `NEXT_PUBLIC_AWS_REGION` | AWS Region (public) | No | eu-west-1 | Frontend app |
| `NEXT_PUBLIC_API_URL` | REST API endpoint | Yes | - | Frontend app |
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID` | Cognito User Pool ID | Yes | - | Frontend app |
| `NEXT_PUBLIC_COGNITO_CLIENT_ID` | Cognito Client ID | Yes | - | Frontend app |
| `NEXT_PUBLIC_APPSYNC_URL` | AppSync GraphQL endpoint | Yes | - | Frontend app |
| `NEXT_PUBLIC_S3_BUCKET` | S3 bucket for file uploads | Yes | - | Frontend app |
| `NEXT_PUBLIC_ENVIRONMENT` | Environment name | No | sandbox | Frontend app |

### Amplify Deployment
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `AMPLIFY_APP_ID` | Amplify App ID | Yes | - | deploy.js |

## Backend Configuration

### Lambda Functions
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | Yes | - | Lambda authorizers |
| `DYNAMODB_TABLE` | DynamoDB table name | Yes | - | Lambda functions |
| `S3_BUCKET` | S3 bucket name | Yes | - | File operations |
| `SES_FROM_EMAIL` | SES sender email | Yes | - | Notifications |
| `AWS_REGION_NAME` | AWS Region (alt name) | No | AWS_REGION | Lambda functions |

## CI/CD Configuration

### GitHub Secrets (GitHub Actions)
| Secret | Description | Required | Environment |
|--------|-------------|----------|-------------|
| `AWS_ROLE_ARN` | IAM Role for OIDC authentication | Yes | All |
| `TF_STATE_BUCKET` | Terraform state S3 bucket | Yes | All |
| `TF_STATE_LOCK_TABLE` | Terraform state lock table | Yes | All |
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | Yes | Per environment |
| `COGNITO_CLIENT_ID` | Cognito Client ID | Yes | Per environment |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | No | All |

### Terraform Backend
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `TF_STATE_BUCKET` | S3 bucket for Terraform state | Yes | - | Terraform |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for state locking | Yes | - | Terraform |

## Testing Configuration

### E2E and Integration Tests
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `TEST_USER_EMAIL` | Test user email address | No | - | E2E tests |
| `TEST_USER_PASSWORD` | Test user password | No | - | E2E tests |
| `TEST_ENVIRONMENT` | Environment for testing | No | sandbox | Tests |

## Script-Specific Variables

### Admin User Creation
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID | Yes | - | create-admin.sh |

### SES Email Verification
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `AWS_REGION` | AWS Region | No | eu-west-1 | verify-ses-email.sh |

### AppSync Resolvers
| Variable | Description | Required | Default | Used In |
|----------|-------------|----------|---------|---------|
| `AWS_REGION` | AWS Region | No | eu-west-1 | create-resolvers.sh |

## Environment Variable Loading

### Priority Order
1. **Environment variables** (highest priority)
2. **GitHub Secrets** (for CI/CD)
3. **`.env` file** (for local development)
4. **`.config` file** (project defaults)
5. **Code defaults** (fallback)

### Loading Methods

#### Local Development
```bash
# Copy template
cp .env.template .env

# Edit with your values
vim .env

# Scripts auto-load from .env
source scripts/load-env.sh
```

#### CI/CD (GitHub Actions)
```yaml
# GitHub Secrets are automatically available
env:
  AWS_REGION: ${{ vars.AWS_REGION }}
  ENVIRONMENT: ${{ vars.ENVIRONMENT }}
```

#### Manual Loading
```bash
# Load environment variables
source scripts/load-env.sh

# Or explicitly load a specific file
load_env_file .env.production
```

## Required Variables by Component

### Minimum Local Development Setup
```bash
# AWS
AWS_REGION=eu-west-1

# Project
PROJECT_NAME=task-manager
ENVIRONMENT=sandbox

# Cognito (from Terraform output)
NEXT_PUBLIC_COGNITO_USER_POOL_ID=eu-west-1_XXXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx

# AppSync (from Terraform output)
NEXT_PUBLIC_APPSYNC_URL=https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql

# Amplify
AMPLIFY_APP_ID=your-app-id
```

### Minimum CI/CD Setup (GitHub Secrets)
```
AWS_ROLE_ARN=arn:aws:iam::XXXXXXXXXXXX:role/github-actions-role
TF_STATE_BUCKET=task-manager-terraform-state
TF_STATE_LOCK_TABLE=task-manager-terraform-locks
```

### Minimum Production Setup
Same as local development + production-specific values

## Getting Values

### From Terraform
```bash
cd terraform
terraform output -json > outputs.json

# Or specific outputs
terraform output -raw appsync_graphql_api_url
terraform output -raw cognito_user_pool_id
```

### Using the Update Script
```bash
# Automatically fetch and update from Terraform
./scripts/update-amplify-env.sh --environment sandbox

# Or with specific values
./scripts/update-amplify-env.sh \
  --environment production \
  --app-id d123abc456def \
  --region eu-west-1
```

### Manual Lookup
```bash
# Cognito User Pool
aws cognito-idp list-user-pools --max-results 10

# AppSync API
aws appsync list-graphql-apis

# Amplify App
aws amplify list-apps
```

## Security Notes

### ⚠️ Never Commit
- `.env` files (in .gitignore)
- Actual values in documentation
- Credentials or tokens

### ✅ Always Use
- `.env.template` for documenting variables
- GitHub Secrets for CI/CD
- Environment variables in Lambda
- `process.env` in all code

### 🔒 Best Practices
1. Different values per environment
2. Rotate credentials regularly
3. Use IAM roles over access keys
4. Enable MFA for AWS accounts
5. Audit access regularly

## Validation

### Check Required Variables
```bash
# Frontend
if [ -z "$NEXT_PUBLIC_COGNITO_USER_POOL_ID" ]; then
  echo "Error: NEXT_PUBLIC_COGNITO_USER_POOL_ID not set"
  exit 1
fi

# Backend
if [ -z "$DYNAMODB_TABLE" ]; then
  echo "Error: DYNAMODB_TABLE not set"
  exit 1
fi
```

### Automated Validation
The scripts automatically validate required variables:
```bash
# scripts/load-env.sh auto-validates
./scripts/create-admin.sh  # Will error if missing vars
```

## Troubleshooting

### Variable Not Found
1. Check `.env` file exists and is loaded
2. Check variable name spelling
3. Check priority order (env vars override .env)
4. Check if variable is exported

### Wrong Values
1. Check which `.env` file is loaded
2. Check for typos in variable names
3. Verify Terraform outputs are current
4. Re-run update-amplify-env.sh

### CI/CD Failures
1. Verify GitHub Secrets are set
2. Check secret names match workflow
3. Verify environment-specific secrets
4. Check IAM role permissions

## Quick Reference

### Set Environment Variables
```bash
# Temporary (current shell)
export AWS_REGION=eu-west-1

# Permanent (add to .env)
echo "AWS_REGION=eu-west-1" >> .env

# GitHub Secret (via CLI)
gh secret set AWS_ROLE_ARN -b "arn:aws:iam::..."
```

### Check Current Values
```bash
# Print all environment variables
printenv | grep AWS_

# Check specific variable
echo $AWS_REGION

# Check in Node.js
node -e "console.log(process.env.AWS_REGION)"
```

### Update All Variables
```bash
# From Terraform outputs
cd terraform
terraform output -json | jq -r 'to_entries|map("\(.key)=\(.value.value)")|.[]' > ../frontend/.env.local

# Or use the update script
./scripts/update-amplify-env.sh --environment sandbox
```

---

**Last Updated**: February 2026  
**Related Docs**: 
- [.env.template](.env.template) - Template file
- [scripts/load-env.sh](scripts/load-env.sh) - Loader script
- [.config](.config) - Project defaults
- [SECURITY_REVIEW.md](SECURITY_REVIEW.md) - Security guide
