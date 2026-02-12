# Documentation Index

Welcome to the AWS Serverless Task Manager documentation! This guide will help you find the information you need.

## 📚 Documentation Structure

```
docs/
├── getting-started/     # Setup and initial configuration
├── configuration/       # Environment and AWS configuration
├── architecture/        # System architecture and design
├── deployment/          # CI/CD and deployment guides
├── development/         # Development guidelines
├── security/           # Security best practices
├── api/                # API reference and integration
└── user-guides/        # End-user documentation
```

## 🚀 Quick Start

**New to the project?** Start here:
1. [Prerequisites & Setup](getting-started/AWS_ACCOUNT_PREPARATION.md)
2. [Quick Start Guide](getting-started/README.md)
3. [Environment Configuration](configuration/README.md)
4. [Deploy Your First Environment](deployment/README.md)

## 📖 Documentation by Role

### For DevOps Engineers

- **[Getting Started](getting-started/README.md)** - Initial setup and prerequisites
- **[Configuration Guide](configuration/README.md)** - Environment variables and AWS setup
- **[Deployment Guide](deployment/README.md)** - CI/CD pipelines and deployment processes
- **[CI/CD Implementation](deployment/CI_CD_IMPLEMENTATION.md)** - Detailed GitHub Actions setup
- **[Security Guide](security/README.md)** - Security best practices and compliance

### For Backend Developers

- **[Development Guide](development/README.md)** - Backend development workflows
- **[Architecture Overview](architecture/README.md)** - System architecture and patterns
- **[API Documentation](api/README.md)** - REST and GraphQL API reference
- **[DynamoDB Access Patterns](architecture/06-dynamodb-access-patterns.md)** - Data modeling

### For Frontend Developers

- **[Development Guide](development/README.md)** - Frontend development setup
- **[API Integration](api/README.md)** - Using REST and GraphQL APIs
- **[Authentication Flow](architecture/02-authentication-flow.md)** - Cognito integration
- **[Frontend README](../frontend/README.md)** - Next.js app documentation

### For Application Users

- **[User Guides](user-guides/README.md)** - Complete user documentation
- **[Admin Guide](user-guides/USER_GUIDE_ADMIN.md)** - For administrators
- **[Member Guide](user-guides/USER_GUIDE_MEMBER.md)** - For team members

## 📂 Detailed Documentation

### 1. Getting Started
- **[Getting Started Guide](getting-started/README.md)** - Complete setup walkthrough
- **[AWS Account Preparation](getting-started/AWS_ACCOUNT_PREPARATION.md)** - AWS prerequisites
- **[Troubleshooting](getting-started/TROUBLESHOOTING.md)** - Common issues and solutions

### 2. Configuration
- **[Configuration Guide](configuration/README.md)** - Complete configuration reference
- **[Environment Variables](configuration/ENV_VARS_REFERENCE.md)** - All variables documented

### 3. Architecture
- **[Architecture Overview](architecture/README.md)** - System architecture summary
- **[High-Level Architecture](architecture/01-high-level-architecture.md)** - Component overview
- **[Authentication Flow](architecture/02-authentication-flow.md)** - Cognito authentication
- **[Data Flow & Database](architecture/03-data-flow-database.md)** - DynamoDB patterns
- **[Event & Notification Flow](architecture/04-event-notification-flow.md)** - Event-driven architecture
- **[Security Architecture](architecture/05-security-architecture.md)** - Security design
- **[DynamoDB Access Patterns](architecture/06-dynamodb-access-patterns.md)** - Data modeling

### 4. Deployment
- **[Deployment Guide](deployment/README.md)** - Complete deployment reference
- **[CI/CD Guide](deployment/CI_CD_GUIDE.md)** - GitHub Actions workflows
- **[CI/CD Implementation](deployment/CI_CD_IMPLEMENTATION.md)** - Detailed implementation
- **[Frontend Deployment](deployment/FRONTEND_DEPLOYMENT.md)** - Amplify deployment
- **[Production Readiness](deployment/PRODUCTION_READINESS_CHECKLIST.md)** - Pre-production checklist

### 5. Development
- **[Development Guide](development/README.md)** - Complete development reference
- **[Code Review Summary](development/CODE_REVIEW_SUMMARY.md)** - Code quality standards
- **[Review Complete](development/REVIEW_COMPLETE.md)** - Latest review results

### 6. Security
- **[Security Guide](security/README.md)** - Complete security reference
- **[Security Review](security/SECURITY_REVIEW.md)** - Security audit results

### 7. API Documentation
- **[API Overview](api/README.md)** - Complete API documentation
- **[API Documentation](api/API_DOCUMENTATION.md)** - REST API reference
- **[Auto Notifications](api/AUTO_NOTIFICATIONS.md)** - Notification system
- **[Member Notifications](api/MEMBER_NOTIFICATIONS.md)** - User notifications
- **[SNS Migration](api/SNS_MIGRATION.md)** - Event system and webhooks

### 8. User Guides
- **[User Guides Overview](user-guides/README.md)** - User documentation index
- **[Admin Guide](user-guides/USER_GUIDE_ADMIN.md)** - Administrator manual
- **[Member Guide](user-guides/USER_GUIDE_MEMBER.md)** - Team member manual

## 🔍 Quick Reference

### Common Tasks

| Task | Documentation |
|------|---------------|
| Initial setup | [Getting Started](getting-started/README.md) |
| Deploy to AWS | [Deployment Guide](deployment/README.md) |
| Configure environment | [Configuration Guide](configuration/README.md) |
| Set up CI/CD | [CI/CD Implementation](deployment/CI_CD_IMPLEMENTATION.md) |
| Develop Lambda functions | [Development Guide](development/README.md) |
| Use the API | [API Documentation](api/README.md) |
| Understand architecture | [Architecture Overview](architecture/README.md) |

### By Technology

| Technology | Documentation |
|------------|---------------|
| **AWS Cognito** | [Authentication Flow](architecture/02-authentication-flow.md) |
| **DynamoDB** | [Access Patterns](architecture/06-dynamodb-access-patterns.md) |
| **Lambda** | [Development Guide](development/README.md) |
| **API Gateway** | [API Documentation](api/README.md) |
| **AppSync** | [API Documentation](api/README.md) |
| **Terraform** | [Deployment Guide](deployment/README.md) |
| **GitHub Actions** | [CI/CD Guide](deployment/CI_CD_GUIDE.md) |
| **Next.js** | [Development Guide](development/README.md) |

## 📦 Additional Resources

### Component-Specific Docs
- **[Frontend README](../frontend/README.md)** - Next.js application
- **[Lambda README](../lambda/README.md)** - Backend functions
- **[Terraform README](../terraform/README.md)** - Infrastructure code

### Configuration Files
- **[.config](../.config)** - Project defaults
- **[.env.template](../.env.template)** - Environment variable template
- **[GitHub Secrets Template](../.github/SECRETS_TEMPLATE.md)** - CI/CD secrets

---

**Documentation Version**: 2.0.0  
**Last Updated**: February 2026  
**Maintained By**: Development Team
