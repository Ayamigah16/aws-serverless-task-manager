# CI/CD Pipeline Documentation

## 🚀 Overview

This repository uses GitHub Actions for continuous integration and continuous deployment (CI/CD). The pipeline automatically builds, tests, and deploys the serverless task management application to AWS.

## 📋 Table of Contents

1. [Architecture](#architecture)
2. [Workflows](#workflows)
3. [Setup Instructions](#setup-instructions)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Deployment Process](#deployment-process)
6. [Environment Management](#environment-management)
7. [Troubleshooting](#troubleshooting)

## 🏗️ Architecture

### Pipeline Components

```
┌─────────────────┐
│   Pull Request  │
│   or Push       │
└────────┬────────┘
         │
         ├─────────────────────────────────────┐
         │                                     │
    ┌────▼─────┐                         ┌────▼──────┐
    │   Test   │                         │   Build   │
    │  Suite   │                         │  & Deploy │
    └────┬─────┘                         └────┬──────┘
         │                                     │
         │                                     │
    ┌────▼──────────────────────────────┬─────▼──────┐
    │  Unit Tests                       │ Terraform  │
    │  Integration Tests                │ Deployment │
    │  E2E Tests                        └────┬───────┘
    │  Security Scans                        │
    │  Code Quality                     ┌────▼───────┐
    └───────────────────────────────────┤   Lambda   │
                                        │ Deployment │
                                        └────┬───────┘
                                             │
                                        ┌────▼───────┐
                                        │  Frontend  │
                                        │ Deployment │
                                        └────┬───────┘
                                             │
                                        ┌────▼───────┐
                                        │   Smoke    │
                                        │   Tests    │
                                        └────────────┘
```

## 📝 Workflows

### 1. Full Stack Deployment (`deploy.yml`)

**Purpose:** Orchestrates the complete deployment process across all components.

**Triggers:**
- Manual dispatch via GitHub Actions UI
- Push to `main` branch (production)

**Workflow:**
1. Determine environment and components to deploy
2. Deploy infrastructure (Terraform) if needed
3. Deploy Lambda functions
4. Deploy frontend application
5. Run smoke tests
6. Generate deployment summary

**Usage:**
```bash
# Via GitHub UI
Actions → Full Stack Deployment → Run workflow
# Select environment and components to deploy

# Or automatically on push to main
git push origin main
```

### 2. Terraform Infrastructure (`terraform-deploy.yml`)

**Purpose:** Manages AWS infrastructure using Terraform.

**Triggers:**
- Called by deploy.yml
- Manual dispatch

**Actions:**
- Terraform format check
- Terraform init
- Terraform plan/apply/destroy
- Upload outputs for use by other workflows

**Usage:**
```bash
# Manual deployment
Actions → Terraform Infrastructure Deployment → Run workflow
# Select: environment, action (plan/apply/destroy)
```

### 3. Lambda Functions Deployment (`lambda-deploy.yml`)

**Purpose:** Builds and deploys Lambda functions to AWS.

**Triggers:**
- Called by deploy.yml
- Push to main/develop with changes in `lambda/` directory
- Manual dispatch

**Actions:**
- Detect changed Lambda functions
- Install dependencies
- Run tests
- Package functions
- Deploy to AWS Lambda
- Build and publish Lambda layers

**Usage:**
```bash
# Automatic on Lambda code changes
git add lambda/*/
git commit -m "Update Lambda functions"
git push

# Manual deployment
Actions → Lambda Functions Deployment → Run workflow
```

### 4. Frontend Deployment (`frontend-deploy.yml`)

**Purpose:** Builds and deploys the Next.js frontend application.

**Triggers:**
- Called by deploy.yml
- Push to main/develop with changes in `frontend/` directory
- Manual dispatch

**Actions:**
- Lint and test frontend code
- Fetch infrastructure outputs from Terraform
- Build Next.js application
- Deploy to AWS Amplify
- Alternative: Deploy to S3 + CloudFront

**Usage:**
```bash
# Automatic on frontend code changes
cd frontend
# Make changes
git commit -am "Update frontend"
git push

# Manual deployment
Actions → Frontend Deployment → Run workflow
```

### 5. Test Suite (`test.yml`)

**Purpose:** Runs comprehensive testing across the application.

**Triggers:**
- Pull requests to main/develop
- Push to main/develop
- Manual dispatch

**Test Types:**
- **Unit Tests:** Jest/Mocha tests for Lambda and frontend
- **Integration Tests:** API and database integration tests
- **E2E Tests:** Playwright browser tests
- **Security Scans:** Trivy, npm audit, secret scanning
- **Terraform Validation:** Format, validate, and lint checks
- **Code Quality:** ESLint, TypeScript checks, shell script validation

**Usage:**
```bash
# Automatic on PR
git checkout -b feature/new-feature
# Make changes
git push origin feature/new-feature
# Create PR → tests run automatically

# Manual test run
Actions → Test Suite → Run workflow
# Select test type (all/unit/integration/e2e/security)
```

## 🔧 Setup Instructions

### 1. AWS Prerequisites

#### Create IAM Role for GitHub Actions

```bash
# Create trust policy for GitHub OIDC
cat > github-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
EOF

# Create the OIDC provider (if not exists)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create the role
aws iam create-role \
  --role-name GitHubActionsDeploymentRole \
  --assume-role-policy-document file://github-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name GitHubActionsDeploymentRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### Create Terraform State Backend

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://task-manager-terraform-state-${AWS_REGION} \
  --region ${AWS_REGION}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket task-manager-terraform-state-${AWS_REGION} \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name task-manager-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${AWS_REGION}
```

### 2. GitHub Repository Setup

#### Configure GitHub Secrets

Navigate to: `Settings → Secrets and variables → Actions → New repository secret`

Add the following secrets:

```bash
# Required Secrets
AWS_ROLE_ARN                    # ARN of GitHubActionsDeploymentRole
TF_STATE_BUCKET                 # S3 bucket name for Terraform state
TF_STATE_LOCK_TABLE            # DynamoDB table for state locking

# Optional Secrets
SLACK_WEBHOOK_URL              # Slack webhook for notifications
TEST_USER_EMAIL                # Email for E2E tests
TEST_USER_PASSWORD             # Password for E2E tests
```

#### Configure GitHub Environments

Create environments for deployment protection:

1. Go to `Settings → Environments`
2. Create three environments:
   - `sandbox` (no protection rules)
   - `staging` (optional reviewers)
   - `production` (required reviewers + deployment branches: main only)

3. Add environment-specific secrets:
   ```
   API_URL                        # API Gateway URL
   COGNITO_USER_POOL_ID          # Cognito User Pool ID
   COGNITO_CLIENT_ID             # Cognito Client ID
   FRONTEND_URL                  # Deployed frontend URL
   ```

### 3. Local Development Setup

```bash
# Clone repository
git clone https://github.com/YOUR_ORG/aws-serverless-task-manager.git
cd aws-serverless-task-manager

# Install dependencies
npm install

# Configure AWS CLI
aws configure

# Setup pre-commit hooks (optional)
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Run tests before commit
npm run lint
npm test
EOF
chmod +x .git/hooks/pre-commit
```

## 🔐 GitHub Secrets Configuration

### Required Secrets

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `AWS_ROLE_ARN` | IAM role ARN for GitHub Actions | From IAM console after role creation |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state | Created in setup step |
| `TF_STATE_LOCK_TABLE` | DynamoDB table for locks | Created in setup step |

### Optional Secrets

| Secret Name | Description | Usage |
|-------------|-------------|-------|
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | For deployment notifications |
| `TEST_USER_EMAIL` | Test user email | For E2E tests |
| `TEST_USER_PASSWORD` | Test user password | For E2E tests |

### Environment-Specific Secrets

Set these for each environment (sandbox, staging, production):

| Secret Name | Description |
|-------------|-------------|
| `API_URL` | API Gateway endpoint URL |
| `COGNITO_USER_POOL_ID` | Cognito User Pool ID |
| `COGNITO_CLIENT_ID` | Cognito App Client ID |
| `FRONTEND_URL` | Frontend application URL |

## 🚀 Deployment Process

### Development Workflow

```bash
# 1. Create feature branch
git checkout -b feature/new-feature

# 2. Make changes and commit
git add .
git commit -m "feat: Add new feature"

# 3. Push and create PR
git push origin feature/new-feature
# Create PR via GitHub UI

# 4. CI runs automatically:
#    ✓ Tests
#    ✓ Linting
#    ✓ Security scans

# 5. After approval, merge to develop
# Staging deployment triggers automatically

# 6. Merge develop to main for production
git checkout main
git merge develop
git push origin main
# Production deployment triggers automatically
```

### Manual Deployment

#### Deploy Everything

```bash
# Via GitHub UI
1. Go to Actions tab
2. Select "Full Stack Deployment"
3. Click "Run workflow"
4. Select:
   - Environment: sandbox/staging/production
   - ✓ Deploy infrastructure
   - ✓ Deploy lambdas
   - ✓ Deploy frontend
5. Click "Run workflow"
```

#### Deploy Specific Component

```bash
# Terraform only
Actions → Terraform Infrastructure Deployment → Run workflow

# Lambda functions only
Actions → Lambda Functions Deployment → Run workflow

# Frontend only
Actions → Frontend Deployment → Run workflow
```

### Rollback Procedure

#### Application Rollback (Lambda/Frontend)

```bash
# Via GitHub UI
1. Go to Actions → Full Stack Deployment
2. Find successful previous deployment
3. Click "Re-run all jobs"

# Via Git
git revert HEAD
git push origin main
```

#### Infrastructure Rollback (Terraform)

```bash
# Local rollback
cd terraform
terraform plan -var-file="environments/production.tfvars"
# Review changes
terraform apply -var-file="environments/production.tfvars"

# OR via GitHub Actions
1. Revert Terraform changes in git
2. Push to trigger deployment
```

## 🌍 Environment Management

### Environment Strategy

| Environment | Branch | Auto-Deploy | Purpose |
|-------------|--------|-------------|---------|
| **Sandbox** | feature/* | No | Development and testing |
| **Staging** | develop | Yes | Pre-production validation |
| **Production** | main | Yes | Live application |

### Environment Configuration

Each environment has its own Terraform variables file:

```
terraform/environments/
├── sandbox.tfvars       # Development
├── staging.tfvars       # Staging
└── production.tfvars    # Production
```

### Promoting Changes

```bash
# Development → Staging
git checkout develop
git merge feature/new-feature
git push origin develop
# Auto-deploys to staging

# Staging → Production
git checkout main
git merge develop
git push origin main
# Auto-deploys to production (with approval)
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Terraform State Lock

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
# Check for stuck locks
aws dynamodb scan --table-name task-manager-terraform-locks

# Force unlock (use with caution)
cd terraform
terraform force-unlock <LOCK_ID>
```

#### 2. Lambda Deployment Timeout

**Error:** `Function does not exist`

**Solution:**
1. Ensure infrastructure is deployed first
2. Check Lambda function names match expected pattern
3. Verify IAM permissions

```bash
# List Lambda functions
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `task-manager`)].FunctionName'
```

#### 3. Frontend Build Fails

**Error:** `Environment variable not set`

**Solution:**
1. Check GitHub environment secrets are configured
2. Ensure Terraform outputs are available
3. Verify `.env.production` is created correctly

```bash
# Check Terraform outputs
cd terraform
terraform output -json
```

#### 4. AWS Credentials Error

**Error:** `Unable to locate credentials`

**Solution:**
1. Verify AWS_ROLE_ARN secret is set correctly
2. Check OIDC provider configuration
3. Ensure IAM role has correct permissions

```bash
# Verify OIDC provider
aws iam list-open-id-connect-providers

# Check role
aws iam get-role --role-name GitHubActionsDeploymentRole
```

### Debugging Workflows

#### View Workflow Logs

```bash
# Via GitHub UI
Actions → Select workflow → Select run → View logs

# Via GitHub CLI
gh run list
gh run view <RUN_ID> --log
```

#### Re-run Failed Jobs

```bash
# Via GitHub UI
Actions → Select failed run → Re-run failed jobs

# Via GitHub CLI
gh run rerun <RUN_ID> --failed
```

### Getting Help

1. **Check Logs:** Review workflow logs in GitHub Actions
2. **AWS Console:** Check CloudWatch logs for Lambda/API Gateway errors
3. **Documentation:** Review [AWS Documentation](https://docs.aws.amazon.com/)
4. **Issues:** Create an issue in the repository

## 📊 Monitoring and Notifications

### Slack Notifications

Configure Slack webhook to receive notifications:

```bash
# Set in GitHub secrets
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

Notifications sent for:
- ✅ Successful deployments
- 🚨 Failed deployments
- ⚠️  Test failures
- 📦 New releases

### GitHub Status Checks

Required status checks for pull requests:
- ✓ Unit Tests
- ✓ Terraform Validation
- ✓ Lint & Format
- ✓ Security Scans

### Deployment Metrics

Track in GitHub Actions:
- Deployment frequency
- Lead time for changes
- Mean time to recovery (MTTR)
- Change failure rate

## 🔒 Security Best Practices

### Secrets Management
- Never commit secrets to git
- Rotate AWS credentials regularly
- Use environment-specific secrets
- Limit secret access to required workflows

### IAM Permissions
- Use least privilege principle
- Separate roles for different environments
- Regular permission audits
- Enable MFA for production access

### Code Security
- Automated security scanning (Trivy)
- Dependency vulnerability checks (npm audit)
- Secret detection (TruffleHog)
- Code review requirements

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Next.js Deployment](https://nextjs.org/docs/deployment)

## 📝 Changelog

Track deployment changes:
- Use conventional commits
- Semantic versioning
- GitHub releases
- CHANGELOG.md file

---

**Last Updated:** February 2026  
**Version:** 2.0.0  
**Maintained by:** DevOps Team
