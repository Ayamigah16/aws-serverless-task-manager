# Serverless Task Management System

A production-grade, secure, serverless task management system built on AWS with enterprise DevSecOps practices.

## 🏗️ Architecture Overview

This system implements a fully serverless, event-driven architecture using:

- **Frontend**: React.js hosted on AWS Amplify
- **Authentication**: Amazon Cognito with email verification and domain restrictions
- **API Layer**: Amazon API Gateway with REST API
- **Compute**: AWS Lambda (Node.js/Python)
- **Database**: Amazon DynamoDB (single-table design)
- **Notifications**: Amazon EventBridge + Amazon SES
- **Infrastructure**: Terraform (IaC)
- **Secrets**: AWS SSM Parameter Store

## 🔐 Security Features

- Email domain restrictions (@amalitech.com, @amalitechtraining.org)
- JWT-based authentication with Cognito
- Role-Based Access Control (RBAC): Admins and Members
- Least-privilege IAM policies
- Encryption at rest and in transit
- API Gateway throttling and WAF integration
- CloudWatch logging and monitoring

## 📋 Prerequisites

### Required Tools
- **AWS CLI**: v2.x or higher
- **Terraform**: v1.5.0 or higher
- **Node.js**: v18.x or higher
- **Python**: v3.11 or higher
- **Git**: v2.x or higher

### AWS Account
- Active AWS Sandbox account
- Appropriate IAM permissions for resource creation
- AWS CLI configured with credentials

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd aws-serverless-task-manager
```

### 2. Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

### 3. Verify Prerequisites
```bash
# Check versions
aws --version
terraform --version
node --version
python --version
```

### 4. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 5. Deploy Frontend
```bash
cd frontend
npm install
npm run build
# Deploy to Amplify (instructions in deployment docs)
```

## 📁 Project Structure

```
aws-serverless-task-manager/
├── terraform/              # Infrastructure as Code
│   ├── modules/           # Reusable Terraform modules
│   │   ├── cognito/       # Authentication
│   │   ├── api-gateway/   # API configuration
│   │   ├── lambda/        # Lambda functions
│   │   ├── dynamodb/      # Database
│   │   ├── eventbridge/   # Event bus
│   │   └── ses/           # Email service
│   └── environments/      # Environment-specific configs
│       └── sandbox/
├── lambda/                # Lambda function code
│   ├── pre-signup-trigger/    # Email domain validation
│   ├── task-api/              # Task management APIs
│   ├── notification-handler/  # Event processing
│   └── shared/                # Shared utilities
├── frontend/              # React application
│   ├── src/
│   │   ├── components/    # UI components
│   │   ├── services/      # API integration
│   │   ├── contexts/      # React contexts
│   │   └── utils/         # Utility functions
│   └── public/
├── docs/                  # Documentation
│   ├── architecture/      # Architecture diagrams
│   ├── security/          # Security documentation
│   └── deployment/        # Deployment guides
└── tests/                 # Test suites
    ├── integration/       # Integration tests
    └── e2e/              # End-to-end tests
```

## 🎯 Features

### Admin Capabilities
- Create tasks
- Update task details
- Assign tasks to members
- Close tasks
- View all tasks

### Member Capabilities
- View assigned tasks
- Update task status
- Receive email notifications

### System Features
- Email verification required before access
- Duplicate assignment prevention
- Event-driven notifications
- Deactivated user filtering
- Comprehensive audit logging

## 🔑 RBAC Model

| Action | Admin | Member |
|--------|-------|--------|
| Create Task | ✅ | ❌ |
| Update Task | ✅ | ❌ |
| Assign Task | ✅ | ❌ |
| Close Task | ✅ | ❌ |
| View Assigned Tasks | ✅ | ✅ |
| Update Task Status | ✅ | ✅ |

## 📚 Documentation

- [Architecture Documentation](docs/architecture/)
- [Security Documentation](docs/security/)
- [Deployment Guide](docs/deployment/)
- [API Documentation](docs/api/)

## 🧪 Testing

```bash
# Run unit tests
cd lambda/task-api
npm test

# Run integration tests
cd tests/integration
npm test

# Run E2E tests
cd tests/e2e
npm test
```

## 🔧 Development

### Local Development Setup
1. Install dependencies
2. Configure environment variables
3. Run local tests
4. Follow coding standards (see .editorconfig)

### Pre-commit Hooks
Security scanning and linting run automatically before commits.

## 📊 Monitoring

- CloudWatch Logs: Lambda execution logs
- CloudWatch Metrics: Custom business metrics
- X-Ray: Distributed tracing
- CloudWatch Alarms: Error and performance alerts

## 💰 Cost Estimation

Estimated monthly cost for sandbox environment: ~$50-100
- Lambda: Pay per invocation
- DynamoDB: On-demand pricing
- API Gateway: Pay per request
- Cognito: Free tier eligible
- SES: Pay per email sent

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit pull request

## 📄 License

[Specify License]

## 👥 Team

DevSecOps Team - AmaliTech

## 📞 Support

For issues or questions, contact: [support-email]

## 🗓️ Project Timeline

**Deadline**: 20th February 2026  
**Status**: In Development

---

**Last Updated**: [Date]
