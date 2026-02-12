# AWS Serverless Task Manager

Production-grade task management system for software engineering teams built on AWS serverless architecture with complete CI/CD pipeline.

## 🚀 Quick Start

### Automated Deployment (Recommended)

```bash
# Full stack deployment (Infrastructure + Lambda Functions + Frontend)
./scripts/deploy.sh --environment sandbox

# Or use CI/CD (push to main/develop)
git push origin main  # Deploys to production
git push origin develop  # Deploys to staging
```

### Component-Specific Deployment

```bash
# Infrastructure & Lambda functions (Terraform handles both)
./scripts/deploy.sh --infrastructure-only

# Frontend configuration only
./scripts/deploy.sh --frontend-only

# Quick deploy (skip pre-build, let Terraform handle it)
./scripts/deploy.sh --skip-build
```

### Manual Setup

```bash
# 1. Deploy backend infrastructure & Lambda functions
cd terraform && terraform init && terraform apply
# Note: Terraform automatically builds and deploys all Lambda functions

# 2. Configure frontend
./setup-amplify.sh
```

**Note**: Lambda functions are now fully managed by Terraform. The deployment script automatically handles building and deploying all functions via `terraform apply`.

## 📋 Architecture

- **Frontend**: Next.js 14 + TypeScript + Tailwind CSS
- **API**: AppSync (GraphQL) + API Gateway (REST)
- **Auth**: Amazon Cognito with RBAC
- **Compute**: AWS Lambda (Node.js)
- **Database**: DynamoDB (single-table design)
- **Storage**: S3 with presigned URLs
- **Search**: OpenSearch Serverless
- **Events**: EventBridge + DynamoDB Streams
- **Notifications**: SES + Real-time subscriptions

## 🏗️ Project Structure

```
├── frontend/          # Next.js application
├── lambda/            # Lambda functions
│   ├── appsync-resolver/
│   ├── task-api/
│   ├── stream-processor/
│   ├── file-processor/
│   └── github-webhook/
├── terraform/         # Infrastructure as Code
│   └── modules/
└── docs/             # Documentation
```

## 📚 Documentation

### Getting Started
- [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md) - **Production deployment guide**
- [Quick Start Guide](./docs/getting-started/README.md) - Complete setup walkthrough
- [AWS Account Preparation](./docs/getting-started/AWS_ACCOUNT_PREPARATION.md) - Prerequisites
- [Troubleshooting](./docs/getting-started/TROUBLESHOOTING.md) - Common issues

### Deployment & Operations
- [Terraform Optimization](./TERRAFORM_OPTIMIZATION.md) - **Lambda deployment via Terraform**
- [Automated Deployment](./scripts/deploy.sh) - One-command full stack deployment
- [CI/CD Pipeline](./docs/deployment/CI_CD_GUIDE.md) - GitHub Actions workflows
- [Scripts Reference](./docs/development/SCRIPTS_REFERENCE.md) - All deployment scripts
- [Deployment Guide](./docs/deployment/README.md) - Manual deployment procedures
- [Secrets Configuration](./.github/SECRETS_TEMPLATE.md) - GitHub secrets setup

### Architecture & Development
- [Integration Guide](./frontend/INTEGRATION.md) - Lambda-Frontend integration
- [Enhancement Plan](./ENHANCEMENT_PLAN.md) - Feature roadmap
- [Architecture](./docs/architecture/) - System design docs

## 🔑 Features

### Core
- ✅ Task CRUD with real-time updates
- ✅ Sprint & project management
- ✅ File attachments (S3)
- ✅ Full-text search (OpenSearch)
- ✅ Comments & mentions
- ✅ GitHub/GitLab integration

### UI/UX
- ✅ Dark mode
- ✅ Responsive design
- ✅ Keyboard shortcuts
- ✅ Drag & drop (board view)
- ✅ Real-time collaboration

### Security
- ✅ Cognito authentication
- ✅ Role-based access control
- ✅ Encryption at rest/transit
- ✅ Presigned URLs for files
- ✅ WAF protection ready

## 🛠️ Development

### Prerequisites
- AWS CLI v2+
- Terraform v1.5+
- Node.js v18+
- npm or yarn

### Environment Setup
```bash
# Backend
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit with your values

# Frontend
cd frontend
cp .env.local.example .env.local
# Or run ./scripts/configure.sh
```

### Local Development
```bash
# Frontend
cd frontend
npm run dev

# Test Lambda locally (optional)
cd lambda/task-api
npm test
```

## 🧪 Testing

```bash
# Frontend
cd frontend
npm run lint
npm run type-check

# Integration test
./scripts/configure.sh
```

## 🚢 Deployment

### Backend
```bash
cd terraform
terraform apply
```

### Frontend
```bash
cd frontend
npm run build

# Deploy to Amplify or Vercel
amplify publish
# or
vercel --prod
```

## 💰 Cost Estimate

**Monthly (Sandbox)**: ~$200-400
- Lambda: $30
- DynamoDB: $10
- AppSync: $20
- OpenSearch: $100
- S3: $10
- Other: $30

## 📊 Performance

- API Latency: <200ms (p95)
- Search: <500ms
- Real-time updates: <100ms
- Lighthouse Score: >90

## 🔒 Security

- JWT authentication
- IAM least-privilege policies
- Encryption (KMS)
- CORS configured
- Input validation
- Audit logging

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Run tests
4. Submit PR

## 📄 License

MIT

## 👥 Support

- Documentation: `/docs`
- Issues: GitHub Issues
- Email: support@example.com

---

**Status**: Production Ready  
**Last Updated**: 2024
