# Lambda-Frontend Integration Guide

## Overview

The frontend seamlessly integrates with AWS Lambda functions through:
- **AppSync GraphQL API** - Real-time queries, mutations, subscriptions
- **REST API Gateway** - Legacy REST endpoints
- **S3 Presigned URLs** - Secure file uploads

## Architecture

```
Frontend (Next.js)
    ↓
AWS Amplify Client
    ↓
┌─────────────────┬──────────────────┬─────────────────┐
│   AppSync       │   API Gateway    │   S3 Bucket     │
│   (GraphQL)     │   (REST)         │   (Files)       │
└────────┬────────┴────────┬─────────┴────────┬────────┘
         ↓                 ↓                  ↓
    Lambda Resolvers   Lambda Functions   File Processor
         ↓                 ↓                  ↓
         └─────────────────┴──────────────────┘
                           ↓
                      DynamoDB
```

## Setup

### 1. Deploy Infrastructure
```bash
cd terraform
terraform apply
```

### 2. Configure Frontend
```bash
cd frontend
./scripts/configure.sh
```

This automatically extracts Terraform outputs and creates `.env.local`

### 3. Install Dependencies
```bash
npm install
```

### 4. Start Development
```bash
npm run dev
```

## API Integration

### GraphQL (AppSync)

**Location**: `lib/graphql/operations.ts`

**Usage**:
```typescript
import { useTasks, useCreateTask } from '@/lib/hooks/use-tasks'

// Query tasks
const { data, isLoading } = useTasks('OPEN')

// Create task
const createTask = useCreateTask()
createTask.mutate({
  title: 'New Task',
  priority: 'HIGH'
})
```

**Subscriptions**:
```typescript
import { useTaskSubscription } from '@/lib/hooks/use-subscriptions'

const updatedTask = useTaskSubscription(taskId)
```

### REST API

**Location**: `lib/api/rest-client.ts`

**Usage**:
```typescript
import { restApi } from '@/lib/api/rest-client'

// List tasks
const tasks = await restApi.listTasks({ status: 'OPEN' })

// Update status
await restApi.updateTaskStatus(taskId, 'IN_PROGRESS')

// Assign task
await restApi.assignTask(taskId, userId)
```

### File Uploads

**Location**: `lib/api/upload.ts`

**Usage**:
```typescript
import { uploadFile } from '@/lib/api/upload'

await uploadFile(file, taskId)
```

**Flow**:
1. Frontend requests presigned URL from AppSync
2. AppSync Lambda generates S3 presigned URL
3. Frontend uploads directly to S3
4. S3 triggers file-processor Lambda
5. Lambda processes file and updates DynamoDB

## Data Types

**Location**: `lib/types.ts`

Types match Lambda DynamoDB schema:
```typescript
interface Task {
  taskId: string
  title: string
  status: TaskStatus
  priority: Priority
  // ... matches Lambda response
}
```

## Authentication

**Flow**:
1. User signs in via Cognito
2. Frontend stores JWT token
3. Amplify automatically includes token in API calls
4. Lambda validates token and extracts user info

**Implementation**:
```typescript
import { useAuthStore } from '@/lib/stores/auth-store'

const { user, isAuthenticated, logout } = useAuthStore()
```

## Real-time Updates

**AppSync Subscriptions**:
```typescript
// Subscribe to task updates
subscription OnTaskUpdated($taskId: ID) {
  onTaskUpdated(taskId: $taskId) {
    taskId
    status
    updatedAt
  }
}
```

**Frontend Hook**:
```typescript
const updatedTask = useTaskSubscription(taskId)

useEffect(() => {
  if (updatedTask) {
    // Update UI automatically
  }
}, [updatedTask])
```

## Error Handling

**GraphQL Errors**:
```typescript
const { data, error } = useTasks()

if (error) {
  toast.error(error.message)
}
```

**REST Errors**:
```typescript
try {
  await restApi.createTask(data)
} catch (error) {
  toast.error('Failed to create task')
}
```

## Environment Variables

Required in `.env.local`:
```bash
NEXT_PUBLIC_USER_POOL_ID=          # From Cognito
NEXT_PUBLIC_USER_POOL_CLIENT_ID=  # From Cognito
NEXT_PUBLIC_APPSYNC_ENDPOINT=      # From AppSync
NEXT_PUBLIC_API_ENDPOINT=          # From API Gateway
NEXT_PUBLIC_S3_BUCKET=             # From S3
NEXT_PUBLIC_AWS_REGION=            # AWS Region
```

## Testing Integration

### Manual Test
```bash
# 1. Check endpoints
curl $NEXT_PUBLIC_API_ENDPOINT/tasks

# 2. Test GraphQL
curl -X POST $NEXT_PUBLIC_APPSYNC_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{"query": "{ listTasks { total } }"}'
```

### Automated Test
```typescript
// Test in browser console
import { restApi } from '@/lib/api/rest-client'

const tasks = await restApi.listTasks()
console.log(tasks)
```

## Common Issues

### 401 Unauthorized
- Check Cognito token is valid
- Verify user is authenticated
- Check API Gateway authorizer configuration

### CORS Errors
- Verify API Gateway CORS settings
- Check S3 bucket CORS configuration
- Ensure Amplify config matches deployed endpoints

### GraphQL Errors
- Verify AppSync endpoint is correct
- Check GraphQL schema matches operations
- Ensure Lambda resolver is deployed

## Performance Optimization

### React Query Caching
```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000, // 1 minute
      cacheTime: 5 * 60 * 1000, // 5 minutes
    },
  },
})
```

### Optimistic Updates
```typescript
const updateTask = useUpdateTask()

updateTask.mutate(data, {
  onMutate: async (newData) => {
    // Update UI immediately
    queryClient.setQueryData(['task', taskId], newData)
  },
})
```

### Subscription Management
```typescript
useEffect(() => {
  const subscription = client.graphql({...}).subscribe({...})
  return () => subscription.unsubscribe() // Cleanup
}, [taskId])
```

## Deployment

### Development
```bash
npm run dev
```

### Production Build
```bash
npm run build
npm start
```

### Deploy to Amplify
```bash
# Connect GitHub repo in Amplify Console
# Or use CLI:
amplify publish
```

## Monitoring

### CloudWatch Logs
- Lambda execution logs
- API Gateway access logs
- AppSync resolver logs

### Frontend Errors
```typescript
// Sentry integration (optional)
import * as Sentry from '@sentry/nextjs'

Sentry.captureException(error)
```

## Security

### API Authentication
- All requests include Cognito JWT
- Lambda validates token
- User groups checked for authorization

### File Uploads
- Presigned URLs expire in 1 hour
- File type validation
- Size limits enforced

### Data Access
- Row-level security in DynamoDB
- Users only see assigned tasks
- Admins have full access

## Support

For issues:
1. Check CloudWatch logs
2. Verify environment variables
3. Test endpoints manually
4. Review integration documentation
