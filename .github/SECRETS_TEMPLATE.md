# GitHub Secrets Configuration Template

This file lists all the secrets required for CI/CD pipelines. 
**DO NOT commit actual secret values to git.**

## Required Repository Secrets

Configure these at: `Settings → Secrets and variables → Actions`

### AWS Configuration

```bash
# IAM Role ARN for GitHub Actions
AWS_ROLE_ARN=arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsDeploymentRole

# Terraform Backend Configuration
TF_STATE_BUCKET=task-manager-terraform-state-REGION
TF_STATE_LOCK_TABLE=task-manager-terraform-locks

# AWS Region (optional, defaults to eu-west-1)
AWS_REGION=eu-west-1
```

### Notification Configuration (Optional)

```bash
# Slack webhook for deployment notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Testing Configuration (Optional)

```bash
# Test user credentials for E2E tests
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=SecurePassword123!
```

## Environment-Specific Secrets

Configure these for each environment: `Settings → Environments → [environment] → Secrets`

### Sandbox Environment

```bash
# API Gateway endpoint
API_URL=https://your-api-id.execute-api.eu-west-1.amazonaws.com/sandbox

# Cognito configuration
COGNITO_USER_POOL_ID=eu-west-1_XXXXXXXXX
COGNITO_CLIENT_ID=your-client-id

# Frontend URL
FRONTEND_URL=https://sandbox.task-manager.amplifyapp.com
```

### Staging Environment

```bash
# API Gateway endpoint
API_URL=https://your-api-id.execute-api.eu-west-1.amazonaws.com/staging

# Cognito configuration
COGNITO_USER_POOL_ID=eu-west-1_XXXXXXXXX
COGNITO_CLIENT_ID=your-client-id

# Frontend URL
FRONTEND_URL=https://staging.task-manager.amplifyapp.com
```

### Production Environment

```bash
# API Gateway endpoint
API_URL=https://your-api-id.execute-api.eu-west-1.amazonaws.com/production

# Cognito configuration
COGNITO_USER_POOL_ID=eu-west-1_XXXXXXXXX
COGNITO_CLIENT_ID=your-client-id

# Frontend URL
FRONTEND_URL=https://task-manager.amplifyapp.com
```

## Quick Setup Commands

### 1. Get AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

### 2. Get Terraform State Bucket Name

```bash
aws s3 ls | grep terraform-state
```

### 3. Get DynamoDB Lock Table Name

```bash
aws dynamodb list-tables --query "TableNames[?contains(@, 'terraform-lock')]" --output text
```

### 4. Get IAM Role ARN

```bash
aws iam get-role --role-name GitHubActionsDeploymentRole --query 'Role.Arn' --output text
```

### 5. Get Cognito Configuration (after deployment)

```bash
# User Pool ID
aws cognito-idp list-user-pools --max-results 10 \
  --query "UserPools[?Name=='task-manager-ENV-users'].Id" --output text

# Client ID
aws cognito-idp list-user-pool-clients --user-pool-id YOUR_POOL_ID \
  --query "UserPoolClients[0].ClientId" --output text
```

### 6. Get API Gateway URL (after deployment)

```bash
aws apigateway get-rest-apis \
  --query "items[?name=='task-manager-ENV'].id" --output text

# Then construct URL:
# https://API_ID.execute-api.REGION.amazonaws.com/ENV
```

## GitHub CLI Setup

If you have GitHub CLI installed, you can set secrets using:

```bash
# Install GitHub CLI
# macOS: brew install gh
# Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md

# Login
gh auth login

# Set repository secrets
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::ACCOUNT:role/ROLE"
gh secret set TF_STATE_BUCKET --body "your-bucket-name"
gh secret set TF_STATE_LOCK_TABLE --body "your-table-name"

# Set environment secrets
gh secret set API_URL --env sandbox --body "https://your-api.amazonaws.com"
gh secret set COGNITO_USER_POOL_ID --env sandbox --body "eu-west-1_XXXXX"
gh secret set COGNITO_CLIENT_ID --env sandbox --body "your-client-id"
```

## Verification

After setting up secrets, verify the configuration:

```bash
# List repository secrets
gh secret list

# List environment secrets
gh secret list --env sandbox
gh secret list --env staging
gh secret list --env production
```

## Troubleshooting

### Secret Not Found Error

If workflows fail with "secret not found":
1. Check secret name matches exactly (case-sensitive)
2. Verify secret is set at correct level (repository vs environment)
3. Ensure environment protection rules allow workflow access

### AWS Credentials Error

If workflows fail with AWS auth errors:
1. Verify AWS_ROLE_ARN is correct
2. Check OIDC provider is configured
3. Ensure role trust policy allows GitHub Actions
4. Verify role has required permissions

### Testing Secrets

Test secrets configuration with a workflow dispatch:

```bash
# Trigger a test workflow
gh workflow run test.yml
gh run watch
```

## Security Best Practices

1. **Rotate secrets regularly** (every 90 days recommended)
2. **Use environment protection rules** for production
3. **Enable audit logging** for secret access
4. **Limit secret access** to only required workflows
5. **Never log secret values** in workflow outputs
6. **Use organization secrets** for shared values across multiple repos

## Additional Resources

- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM OIDC Configuration](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments)

---

**Last Updated:** February 2026
