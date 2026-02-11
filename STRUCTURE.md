# Project Structure

```
aws-serverless-task-manager/
├── frontend/                    # Next.js 14 Application
│   ├── app/                    # App Router pages
│   │   ├── dashboard/         # Dashboard page
│   │   ├── tasks/            # Tasks list/board
│   │   ├── login/            # Authentication
│   │   ├── layout.tsx        # Root layout
│   │   └── globals.css       # Global styles
│   ├── components/
│   │   ├── ui/               # Base components (Button, Input, Card)
│   │   ├── layout/           # Sidebar, Header
│   │   ├── tasks/            # TaskCard, TaskList
│   │   └── providers.tsx     # React Query, Theme providers
│   ├── lib/
│   │   ├── api/              # REST & upload clients
│   │   ├── graphql/          # GraphQL operations
│   │   ├── hooks/            # React Query hooks
│   │   ├── stores/           # Zustand stores
│   │   ├── types.ts          # TypeScript types
│   │   └── utils.ts          # Utilities
│   ├── scripts/
│   │   └── configure.sh      # Auto-config from Terraform
│   ├── package.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   └── next.config.js
│
├── lambda/                      # Lambda Functions
│   ├── appsync-resolver/       # GraphQL resolver
│   ├── task-api/               # REST API handler
│   ├── stream-processor/       # DynamoDB → OpenSearch
│   ├── file-processor/         # S3 event handler
│   ├── presigned-url/          # File upload URLs
│   ├── github-webhook/         # Git integration
│   ├── notification-handler/   # Event notifications
│   ├── pre-signup-trigger/     # Email validation
│   ├── users-api/              # User management
│   └── layers/
│       └── shared-layer/       # Common utilities
│
├── terraform/                   # Infrastructure as Code
│   ├── modules/
│   │   ├── api-gateway/       # REST API
│   │   ├── appsync/           # GraphQL API
│   │   ├── cognito/           # Authentication
│   │   ├── dynamodb/          # Database
│   │   ├── eventbridge/       # Event bus
│   │   ├── lambda/            # Functions
│   │   ├── opensearch/        # Search service
│   │   ├── s3/                # File storage
│   │   ├── ses/               # Email service
│   │   └── cloudwatch-alarms/ # Monitoring
│   ├── main.tf                # Root module
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── docs/                        # Documentation
│   ├── architecture/           # System design
│   ├── deployment/            # Deployment guides
│   ├── ENHANCED_DEPLOYMENT_GUIDE.md
│   ├── TROUBLESHOOTING.md
│   └── USER_GUIDE_*.md
│
├── scripts/                     # Utility scripts
│   ├── build-lambdas.sh
│   ├── create-admin.sh
│   └── verify-ses-email.sh
│
├── schema.graphql              # AppSync schema
├── README.md                   # Main documentation
├── ENHANCEMENT_PLAN.md         # Feature roadmap
├── ENHANCEMENT_SUMMARY.md      # Implementation summary
└── .gitignore

```

## Key Files

### Frontend
- `app/layout.tsx` - Root layout with providers
- `components/providers.tsx` - React Query, Theme setup
- `lib/amplify-config.ts` - AWS configuration
- `lib/hooks/use-tasks.ts` - Task data hooks
- `lib/graphql/operations.ts` - GraphQL queries/mutations

### Backend
- `lambda/appsync-resolver/index.js` - GraphQL resolver
- `lambda/task-api/index.js` - REST API handler
- `terraform/main.tf` - Infrastructure root
- `schema.graphql` - API schema

### Configuration
- `frontend/.env.local` - Frontend environment (auto-generated)
- `terraform/terraform.tfvars` - Infrastructure config
- `frontend/scripts/configure.sh` - Auto-setup script

## File Counts

- Lambda Functions: 9
- Terraform Modules: 9
- React Components: 15+
- Documentation Files: 20+
- Total Lines of Code: ~8,000
