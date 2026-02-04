# Development Setup Guide

## 📋 Prerequisites

### Required Software

#### AWS CLI (v2.x or higher)
```bash
# Install on Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

#### Terraform (v1.5.0 or higher)
```bash
# Install on Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version
```

#### Node.js (v18.x or higher)
```bash
# Install using nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Verify installation
node --version
npm --version
```

#### Python (v3.11 or higher)
```bash
# Install on Linux
sudo apt update
sudo apt install python3.11 python3.11-venv python3-pip

# Verify installation
python3 --version
pip3 --version
```

## 🔧 AWS Configuration

### 1. Configure AWS Credentials
```bash
aws configure
```

Enter the following when prompted:
- **AWS Access Key ID**: [Your access key]
- **AWS Secret Access Key**: [Your secret key]
- **Default region name**: us-east-1 (or your preferred region)
- **Default output format**: json

### 2. Verify AWS Access
```bash
# Test AWS connectivity
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/username"
# }
```

### 3. Set AWS Region
```bash
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
```

## 🏗️ Project Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd aws-serverless-task-manager
```

### 2. Install Lambda Dependencies

#### Node.js Lambda Functions
```bash
cd lambda/task-api
npm install

cd ../notification-handler
npm install

cd ../pre-signup-trigger
npm install
```

#### Python Lambda Functions (if applicable)
```bash
cd lambda/shared
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Install Frontend Dependencies
```bash
cd frontend
npm install
```

### 4. Install Development Tools
```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Install security scanning tools
npm install -g snyk
pip install bandit
```

## 🔐 Environment Configuration

### 1. Create Environment Files

**DO NOT commit these files to Git**

#### Terraform Variables
```bash
cd terraform/environments/sandbox
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
aws_region     = "us-east-1"
environment    = "sandbox"
project_name   = "task-manager"
admin_email    = "admin@amalitech.com"
```

#### Frontend Environment
```bash
cd frontend
cp .env.example .env.local
```

Edit `.env.local`:
```
REACT_APP_API_URL=https://api.example.com
REACT_APP_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
REACT_APP_COGNITO_CLIENT_ID=XXXXXXXXXXXXXXXXXXXXXXXXXX
REACT_APP_COGNITO_DOMAIN=task-manager-sandbox
REACT_APP_REGION=us-east-1
```

## 🚀 Local Development

### 1. Terraform Development
```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes (when ready)
terraform apply
```

### 2. Lambda Development

#### Run Unit Tests
```bash
cd lambda/task-api
npm test

# With coverage
npm run test:coverage
```

#### Local Lambda Testing (using SAM)
```bash
# Install AWS SAM CLI
pip install aws-sam-cli

# Invoke function locally
sam local invoke TaskApiFunction -e events/create-task.json
```

### 3. Frontend Development
```bash
cd frontend

# Start development server
npm start

# Run tests
npm test

# Build for production
npm run build

# Run linter
npm run lint

# Format code
npm run format
```

## 🧪 Testing

### Unit Tests
```bash
# Lambda tests
cd lambda/task-api
npm test

# Frontend tests
cd frontend
npm test
```

### Integration Tests
```bash
cd tests/integration
npm install
npm test
```

### E2E Tests
```bash
cd tests/e2e
npm install
npm run test:e2e
```

## 🔍 Code Quality

### Linting
```bash
# JavaScript/TypeScript
npm run lint

# Python
pylint lambda/**/*.py

# Terraform
terraform fmt -check -recursive
```

### Security Scanning
```bash
# Dependency scanning
npm audit
snyk test

# Secret scanning
git secrets --scan

# Terraform security
tfsec terraform/
checkov -d terraform/
```

## 📊 Monitoring & Debugging

### View CloudWatch Logs
```bash
# List log groups
aws logs describe-log-groups

# Tail logs
aws logs tail /aws/lambda/task-api-function --follow
```

### X-Ray Traces
```bash
# Get trace summaries
aws xray get-trace-summaries --start-time $(date -u -d '1 hour ago' +%s) --end-time $(date +%s)
```

## 🐛 Troubleshooting

### Common Issues

#### Terraform State Lock
```bash
# If state is locked
terraform force-unlock <LOCK_ID>
```

#### AWS Credentials Expired
```bash
# Refresh credentials
aws configure
aws sts get-caller-identity
```

#### Lambda Deployment Fails
```bash
# Check Lambda package size
cd lambda/task-api
du -sh node_modules/

# Remove dev dependencies
npm prune --production
```

#### Frontend Build Fails
```bash
# Clear cache
rm -rf node_modules package-lock.json
npm install
```

## 📚 Additional Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [React Documentation](https://react.dev/)

## 🤝 Getting Help

- Check existing documentation in `docs/`
- Review TODO.md for project status
- Contact team lead for access issues
- Create GitHub issue for bugs

---

**Last Updated**: [Date]
