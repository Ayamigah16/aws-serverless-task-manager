# Getting Started

Complete guide to setting up and deploying your AWS Serverless Task Manager.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [AWS Account Setup](#aws-account-setup)
- [Local Development](#local-development)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

### Required Tools
- **Node.js** 18.x or higher
- **npm** 9.x or higher
- **AWS CLI** v2+ configured with credentials
- **Terraform** 1.5.0 or higher
- **Git** for version control

### AWS Account Requirements
- Active AWS account with appropriate permissions
- IAM user with AdministratorAccess or equivalent
- AWS CLI configured (`aws configure`)

### GitHub (for CI/CD)
- GitHub account
- Repository with Actions enabled
- OIDC provider configured for GitHub Actions

## Quick Start

### 1. Clone and Install

```bash
# Clone the repository
git clone <your-repo-url>
cd aws-serverless-task-manager

# Install dependencies
npm install

# Install frontend dependencies
cd frontend && npm install && cd ..

# Install Lambda dependencies
for dir in lambda/*/; do
  if [ -f "${dir}package.json" ]; then
    (cd "$dir" && npm install)
  fi
done
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.template .env

# Edit with your values
vim .env
```

**Required Variables:**
```bash
AWS_REGION=eu-west-1
AWS_ACCOUNT_ID=123456789012
PROJECT_NAME=task-manager
ENVIRONMENT=sandbox
```

See [Environment Variables Guide](../configuration/ENV_VARS_REFERENCE.md) for complete reference.

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
cd terraform
terraform init

# Select workspace (or create new)
terraform workspace select sandbox || terraform workspace new sandbox

# Deploy infrastructure
terraform apply -var-file="environments/sandbox.tfvars"

# Note the outputs
terraform output -json > ../outputs.json
cd ..
```

### 4. Configure Frontend

```bash
# Update Amplify environment variables
./scripts/update-amplify-env.sh --environment sandbox

# Or manually update .env in frontend
cd frontend
cp ../outputs.json .
# Extract values and update .env.local
```

### 5. Deploy Application

#### Option A: Using CI/CD (Recommended)

```bash
# Push to main branch
git add .
git commit -m "Initial deployment"
git push origin main

# GitHub Actions will automatically deploy
```

#### Option B: Manual Deployment

```bash
# Deploy Lambda functions
./scripts/build-lambdas.sh

# Deploy frontend
cd frontend
npm run build
amplify publish
```

### 6. Create Admin User

```bash
# Create your first admin user
./scripts/create-admin.sh admin@example.com
```

### 7. Verify Deployment

```bash
# Run end-to-end tests
npm run test:e2e

# Or manually test
# Visit your Amplify URL and login
```

## AWS Account Setup

For detailed AWS account preparation, see [AWS Account Preparation Guide](AWS_ACCOUNT_PREPARATION.md).

### Quick Setup Checklist

- [ ] AWS account created and accessible
- [ ] IAM user with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] S3 bucket for Terraform state created
- [ ] DynamoDB table for state locking created
- [ ] SES email identity verified (for notifications)
- [ ] Cognito User Pool created (via Terraform)
- [ ] GitHub OIDC provider configured (for CI/CD)

### Automated Setup

```bash
# Run the CI/CD setup script
./scripts/setup-cicd.sh

# This will:
# - Create S3 bucket for Terraform state
# - Create DynamoDB table for state locking
# - Set up GitHub OIDC provider
# - Create IAM role for deployments
# - Generate GitHub secrets configuration
```

## Local Development

### Backend Development

```bash
# Test Lambda functions locally
cd lambda/task-api
npm test

# Run with SAM Local (optional)
sam local start-api
```

### Frontend Development

```bash
cd frontend

# Start development server
npm run dev

# Open http://localhost:3000
```

**Mock Backend (Development):**
```bash
# Set environment variable
export NEXT_PUBLIC_API_URL=http://localhost:3001

# Run local mock API (if available)
npm run dev:api
```

### Testing

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests (requires deployed infrastructure)
npm run test:e2e

# Security scans
npm run test:security
```

## Environment-Specific Setup

### Sandbox Environment
```bash
terraform workspace select sandbox
terraform apply -var-file="environments/sandbox.tfvars"
```

### Staging Environment
```bash
terraform workspace select staging
terraform apply -var-file="environments/staging.tfvars"
```

### Production Environment
```bash
terraform workspace select production
terraform apply -var-file="environments/production.tfvars"

# Note: Production requires additional security reviews
# See docs/deployment/PRODUCTION_READINESS_CHECKLIST.md
```

## Using Docker (Optional)

If you prefer containerized development:

```bash
# Build development container
docker build -t task-manager-dev .

# Run with mounted volumes
docker run -v $(pwd):/app -p 3000:3000 task-manager-dev

# Run tests in container
docker run task-manager-dev npm test
```

## Common Setup Issues

### AWS Credentials Not Found
```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=eu-west-1
```

### Terraform State Locked
```bash
# If state is locked (after failed deployment)
cd terraform
terraform force-unlock <lock-id>

# Or manually remove from DynamoDB
aws dynamodb delete-item \
  --table-name task-manager-terraform-locks \
  --key '{"LockID":{"S":"task-manager-state-lock"}}'
```

### Node Version Issues
```bash
# Use nvm to manage Node versions
nvm install 18
nvm use 18

# Verify version
node --version  # Should be 18.x
```

### Permission Denied Errors
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run with explicit shell
bash scripts/setup-cicd.sh
```

For more troubleshooting, see [Troubleshooting Guide](TROUBLESHOOTING.md).

## Next Steps

After successful setup:

1. **Configure CI/CD**: [Deployment Guide](../deployment/README.md)
2. **Understand Architecture**: [Architecture Docs](../architecture/README.md)
3. **API Integration**: [API Documentation](../api/README.md)
4. **Security Review**: [Security Guide](../security/README.md)
5. **User Management**: [Admin Guide](../user-guides/USER_GUIDE_ADMIN.md)

## Additional Resources

- [Configuration Guide](../configuration/README.md) - Environment variables and settings
- [Development Guide](../development/README.md) - Backend and frontend development
- [Deployment Guide](../deployment/README.md) - CI/CD and production deployment
- [API Reference](../api/README.md) - Complete API documentation

## Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/discussions)
- **Documentation**: [Main README](../../README.md)

---

**Last Updated**: February 2026  
**Maintained By**: DevOps Team
