# AWS Serverless Task Manager

Production-grade task management system for software engineering teams built on AWS serverless architecture with complete CI/CD pipeline.

## 🚀 Quick Start

### Deployment Overview
This project uses a **hybrid deployment approach**:
- **Backend** (Terraform): Cognito, AppSync, Lambda, DynamoDB, S3, SNS, EventBridge
- **Frontend** (AWS Amplify Console): Next.js app deployed manually via AWS Console

### Backend Deployment

```bash
# Deploy all backend infrastructure and Lambda functions
cd terraform
terraform init
terraform apply
```

**Note**: Terraform automatically builds and deploys all Lambda functions. No separate Lambda deployment needed.

### Frontend Deployment

Frontend is deployed via AWS Amplify Console for optimal Next.js SSR support:

```bash
# See comprehensive setup guide
cat AMPLIFY_CONSOLE_SETUP.md
```

**Why not Terraform?**
- Terraform Amplify provider lacks monorepo `app_root` support
- Manual Console setup provides better Next.js SSR detection
- Visual configuration and debugging capabilities

See [AMPLIFY_CONSOLE_SETUP.md](AMPLIFY_CONSOLE_SETUP.md) for complete step-by-step instructions.

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
- [**Amplify Console Setup**](./AMPLIFY_CONSOLE_SETUP.md) - **Frontend deployment guide (REQUIRED)**
- [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md) - Production deployment checklist
- [Quick Start Guide](./docs/getting-started/README.md) - Complete setup walkthrough
- [AWS Account Preparation](./docs/getting-started/AWS_ACCOUNT_PREPARATION.md) - Prerequisites
- [Troubleshooting](./docs/getting-started/TROUBLESHOOTING.md) - Common issues

### Deployment & Operations
- [Terraform Backend](./terraform/README.md) - Backend infrastructure deployment
- [CI/CD Pipeline](./docs/deployment/CI_CD_GUIDE.md) - GitHub Actions workflows
- [Scripts Reference](./docs/development/SCRIPTS_REFERENCE.md) - Utility scripts
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
