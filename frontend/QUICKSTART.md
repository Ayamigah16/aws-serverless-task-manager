# Quick Start - Lambda & Frontend Integration

## 🚀 One-Command Setup

```bash
# From project root
cd terraform && terraform apply -auto-approve && \
cd ../frontend && ./scripts/configure.sh && npm install && npm run dev
```

## 📋 Step-by-Step

### 1. Deploy Backend (5 min)
```bash
cd terraform
terraform init
terraform apply
```

### 2. Configure Frontend (30 sec)
```bash
cd ../frontend
./scripts/configure.sh  # Auto-extracts Terraform outputs
```

### 3. Start Development (1 min)
```bash
npm install
npm run dev
```

Open http://localhost:3000

## ✅ Verify Integration

### Test GraphQL
```bash
# In browser console
import { useTasks } from '@/lib/hooks/use-tasks'
const { data } = useTasks()
console.log(data)
```

### Test REST API
```bash
curl $NEXT_PUBLIC_API_ENDPOINT/tasks
```

### Test Authentication
1. Go to http://localhost:3000/login
2. Sign in with Cognito credentials
3. Should redirect to dashboard

## 🔧 Manual Configuration

If auto-config fails, create `.env.local`:

```bash
# Get from Terraform outputs
cd terraform
terraform output

# Create .env.local
cd ../frontend
cat > .env.local <<EOF
NEXT_PUBLIC_USER_POOL_ID=$(cd ../terraform && terraform output -raw cognito_user_pool_id)
NEXT_PUBLIC_USER_POOL_CLIENT_ID=$(cd ../terraform && terraform output -raw cognito_user_pool_client_id)
NEXT_PUBLIC_APPSYNC_ENDPOINT=$(cd ../terraform && terraform output -raw appsync_graphql_endpoint)
NEXT_PUBLIC_API_ENDPOINT=$(cd ../terraform && terraform output -raw api_gateway_url)
NEXT_PUBLIC_S3_BUCKET=$(cd ../terraform && terraform output -raw s3_bucket_name)
NEXT_PUBLIC_AWS_REGION=us-east-1
EOF
```

## 🎯 Key Integration Points

### GraphQL Operations → Lambda Resolvers
- `LIST_TASKS` → `appsync-resolver/index.js:listTasks()`
- `CREATE_TASK` → `appsync-resolver/index.js:createTask()`
- `UPDATE_TASK` → `appsync-resolver/index.js:updateTask()`

### REST Endpoints → Lambda Functions
- `GET /tasks` → `task-api/index.js:listTasks()`
- `POST /tasks` → `task-api/index.js:createTask()`
- `PUT /tasks/{id}` → `task-api/index.js:updateTask()`

### File Uploads → S3 → Lambda
- Frontend → Presigned URL → S3 → `file-processor/index.js`

## 🐛 Troubleshooting

### "Cannot connect to API"
```bash
# Check endpoints
echo $NEXT_PUBLIC_API_ENDPOINT
echo $NEXT_PUBLIC_APPSYNC_ENDPOINT

# Test connectivity
curl $NEXT_PUBLIC_API_ENDPOINT/tasks
```

### "Authentication failed"
```bash
# Verify Cognito config
aws cognito-idp describe-user-pool --user-pool-id $NEXT_PUBLIC_USER_POOL_ID
```

### "GraphQL errors"
```bash
# Check AppSync logs
aws logs tail /aws/appsync/task-manager-sandbox-graphql --follow
```

## 📚 Next Steps

1. Read [INTEGRATION.md](./INTEGRATION.md) for detailed docs
2. Review [README.md](./README.md) for component usage
3. Check Lambda logs in CloudWatch
4. Test real-time subscriptions

## 🎉 Success!

You now have:
- ✅ Backend deployed (Lambda, DynamoDB, AppSync)
- ✅ Frontend configured and running
- ✅ Seamless integration between all services
- ✅ Real-time updates working
- ✅ Authentication flow complete
