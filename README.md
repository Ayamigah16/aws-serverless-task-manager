# AWS Serverless Task Manager

Production-grade task management system for software engineering teams built on AWS serverless architecture.

## 🚀 Quick Start

```bash
# 1. Deploy backend
cd terraform && terraform init && terraform apply

# 2. Configure frontend
cd ../frontend && ./scripts/configure.sh

# 3. Start development
npm install && npm run dev
```

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

- [Frontend Guide](./frontend/README.md) - Next.js setup and usage
- [Integration Guide](./frontend/INTEGRATION.md) - Lambda-Frontend integration
- [Quick Start](./frontend/QUICKSTART.md) - Fast setup guide
- [Enhancement Plan](./ENHANCEMENT_PLAN.md) - Feature roadmap
- [Deployment Guide](./docs/ENHANCED_DEPLOYMENT_GUIDE.md) - Production deployment
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
