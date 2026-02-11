# Documentation

## 📚 Quick Links

### Getting Started
- [Main README](../README.md) - Project overview
- [Frontend Quick Start](../frontend/QUICKSTART.md) - Fast setup
- [Integration Guide](../frontend/INTEGRATION.md) - Lambda-Frontend connection

### Architecture
- [High-Level Architecture](./architecture/01-high-level-architecture.md)
- [Authentication Flow](./architecture/02-authentication-flow.md)
- [Data Flow](./architecture/03-data-flow-database.md)
- [DynamoDB Access Patterns](./architecture/06-dynamodb-access-patterns.md)

### Deployment
- [Enhanced Deployment Guide](./ENHANCED_DEPLOYMENT_GUIDE.md) - Complete deployment
- [Frontend Deployment](./deployment/FRONTEND_DEPLOYMENT.md)

### Operations
- [Troubleshooting](./TROUBLESHOOTING.md)
- [Production Checklist](./PRODUCTION_READINESS_CHECKLIST.md)
- [Project Status](./PROJECT_STATUS.md)

### User Guides
- [Admin Guide](./USER_GUIDE_ADMIN.md)
- [Member Guide](./USER_GUIDE_MEMBER.md)

### API
- [API Documentation](./API_DOCUMENTATION.md)
- [GraphQL Operations](../frontend/lib/graphql/operations.ts)

## 🎯 Common Tasks

### Deploy Everything
```bash
cd terraform && terraform apply && \
cd ../frontend && ./scripts/configure.sh && npm install && npm run dev
```

### Update Frontend Config
```bash
cd frontend && ./scripts/configure.sh
```

### View Logs
```bash
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow
```

### Test Integration
```bash
curl $NEXT_PUBLIC_API_ENDPOINT/tasks
```

## 📖 Documentation Structure

```
docs/
├── architecture/       # System design
├── deployment/        # Deployment guides
├── API_DOCUMENTATION.md
├── ENHANCED_DEPLOYMENT_GUIDE.md
├── TROUBLESHOOTING.md
└── USER_GUIDE_*.md
```

## 🔗 External Resources

- [AWS Amplify Docs](https://docs.amplify.aws/)
- [Next.js Docs](https://nextjs.org/docs)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
