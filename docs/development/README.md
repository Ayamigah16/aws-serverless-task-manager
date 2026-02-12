# Development Guide

Comprehensive guide for backend and frontend development on the AWS Serverless Task Manager.

## 📋 Table of Contents

- [Development Setup](#development-setup)
- [Backend Development](#backend-development)
- [Frontend Development](#frontend-development)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Code Review Process](#code-review-process)

## Development Setup

### Prerequisites

- Node.js 18.x or higher
- AWS CLI configured
- Git
- VS Code (recommended) or your preferred IDE

### Initial Setup

```bash
# Clone repository
git clone <repo-url>
cd aws-serverless-task-manager

# Install dependencies
npm install
cd frontend && npm install && cd ..

# Set up environment
cp .env.template .env
# Edit .env with your configuration

# Load environment
source scripts/load-env.sh
```

### IDE Setup

**VS Code Extensions** (recommended):
- ESLint
- Prettier
- AWS Toolkit
- Terraform
- GitLens
- REST Client

**.vscode/settings.json**:
```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "frontend/node_modules/typescript/lib"
}
```

## Backend Development

### Lambda Functions

#### Structure

```
lambda/
├── task-api/           # Task CRUD operations
├── users-api/          # User management
├── notification-handler/ # Event-driven notifications
├── stream-processor/   # DynamoDB streams processor
├── presigned-url/      # S3 upload/download URLs
├── appsync-resolver/   # GraphQL resolvers
├── github-webhook/     # GitHub integration
├── file-processor/     # File processing
├── pre-signup-trigger/ # Cognito trigger
└── layers/
    └── shared-layer/   # Shared utilities
```

#### Development Workflow

**Local Development**:
```bash
# Navigate to function
cd lambda/task-api

# Install dependencies
npm install

# Run tests
npm test

# Run with watch mode
npm test -- --watch

# Type checking (if TypeScript)
npx tsc --noEmit
```

**Local Testing with SAM** (optional):
```bash
# Build
sam build

# Start local API
sam local start-api

# Invoke function locally
sam local invoke TaskApiFunction --event events/create-task.json
```

**Environment Variables**:
```javascript
// Lambda function receives env vars from Terraform
const {
  AWS_REGION,
  DYNAMODB_TABLE,
  COGNITO_USER_POOL_ID,
  S3_BUCKET,
  ENVIRONMENT
} = process.env;
```

#### Creating New Lambda Function

```bash
# 1. Create directory
mkdir lambda/new-function
cd lambda/new-function

# 2. Initialize package.json
npm init -y

# 3. Create index.js
cat > index.js << 'EOF'
exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  try {
    // Your logic here
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Success' })
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
EOF

# 4. Add to Terraform
vim terraform/modules/lambda/main.tf

# 5. Test locally
npm test

# 6. Deploy
./scripts/build-lambdas.sh
```

#### Best Practices

- ✅ Use async/await for asynchronous operations
- ✅ Validate input early
- ✅ Use structured logging
- ✅ Handle errors gracefully
- ✅ Set appropriate timeouts
- ✅ Use environment variables for configuration
- ✅ Keep functions small and focused
- ✅ Use shared layer for common code

#### Testing Lambda Functions

```javascript
// lambda/task-api/__tests__/handler.test.js
const { handler } = require('../index');

describe('Task API Handler', () => {
  const mockEvent = {
    httpMethod: 'POST',
    body: JSON.stringify({
      title: 'Test Task',
      description: 'Test Description'
    })
  };

  it('should create a task', async () => {
    const response = await handler(mockEvent);
    expect(response.statusCode).toBe(201);
    
    const body = JSON.parse(response.body);
    expect(body).toHaveProperty('taskId');
  });

  it('should handle errors', async () => {
    const invalidEvent = { ...mockEvent, body: 'invalid json' };
    const response = await handler(invalidEvent);
    expect(response.statusCode).toBe(400);
  });
});
```

### Shared Layer Development

```bash
# Build layer
cd lambda/layers/shared-layer
npm install

# Test layer
npm test

# Build for deployment
./scripts/build-layer.sh

# Deploy layer
aws lambda publish-layer-version \
  --layer-name task-manager-shared-layer \
  --zip-file fileb://layer.zip \
  --compatible-runtimes nodejs18.x
```

**Using Shared Layer**:
```javascript
// In Lambda function
const { validateToken, formatResponse } = require('/opt/nodejs/auth');
```

### DynamoDB Access Patterns

See [DynamoDB Access Patterns](../architecture/06-dynamodb-access-patterns.md) for complete reference.

**Common Patterns**:
```javascript
// Get tasks by user
const params = {
  TableName: process.env.DYNAMODB_TABLE,
  KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
  ExpressionAttributeValues: {
    ':pk': `USER#${userId}`,
    ':sk': 'TASK#'
  }
};

// Query with index
const params = {
  TableName: process.env.DYNAMODB_TABLE,
  IndexName: 'GSI1',
  KeyConditionExpression: 'GSI1PK = :pk',
  ExpressionAttributeValues: {
    ':pk': `PROJECT#${projectId}`
  }
};
```

## Frontend Development

### Structure

```
frontend/
├── app/                # Next.js app directory
│   ├── (auth)/        # Authentication routes
│   ├── (dashboard)/   # Dashboard routes
│   └── api/           # API routes
├── components/        # React components
│   ├── ui/           # UI components (shadcn/ui)
│   ├── tasks/        # Task components
│   ├── projects/     # Project components
│   └── common/       # Shared components
├── lib/              # Utilities
│   ├── amplify-config.ts
│   ├── api.ts
│   └── utils.ts
├── public/           # Static assets
└── styles/           # Global styles
```

### Development Server

```bash
cd frontend

# Start development server
npm run dev

# Open http://localhost:3000
```

### Environment Configuration

```bash
# frontend/.env.local
NEXT_PUBLIC_AWS_REGION=eu-west-1
NEXT_PUBLIC_COGNITO_USER_POOL_ID=eu-west-1_XXXXX
NEXT_PUBLIC_COGNITO_CLIENT_ID=xxxxxxxxxxxx
NEXT_PUBLIC_APPSYNC_URL=https://xxx.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_S3_BUCKET=uploads-bucket
```

### Creating Components

```tsx
// components/tasks/TaskCard.tsx
import { Card } from '@/components/ui/card';

interface TaskCardProps {
  task: {
    id: string;
    title: string;
    description: string;
    status: string;
  };
  onEdit?: (id: string) => void;
  onDelete?: (id: string) => void;
}

export function TaskCard({ task, onEdit, onDelete }: TaskCardProps) {
  return (
    <Card className="p-4">
      <h3 className="text-lg font-semibold">{task.title}</h3>
      <p className="text-sm text-gray-600">{task.description}</p>
      <div className="mt-4 flex gap-2">
        {onEdit && (
          <button onClick={() => onEdit(task.id)}>Edit</button>
        )}
        {onDelete && (
          <button onClick={() => onDelete(task.id)}>Delete</button>
        )}
      </div>
    </Card>
  );
}
```

### API Integration

```typescript
// lib/api.ts
import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/api';

const client = generateClient();

// GraphQL query
export async function getTasks(userId: string) {
  const { data } = await client.graphql({
    query: `
      query GetMyTasks($userId: ID!) {
        getMyTasks(userId: $userId) {
          items {
            id
            title
            description
            status
          }
        }
      }
    `,
    variables: { userId }
  });
  
  return data.getMyTasks.items;
}

// REST API call
export async function createTask(task: Task) {
  const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/tasks`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${await getAuthToken()}`
    },
    body: JSON.stringify(task)
  });
  
  if (!response.ok) {
    throw new Error('Failed to create task');
  }
  
  return response.json();
}
```

### State Management

Using React Context:
```typescript
// contexts/TaskContext.tsx
import { createContext, useContext, useState } from 'react';

interface TaskContextType {
  tasks: Task[];
  addTask: (task: Task) => void;
  updateTask: (id: string, task: Partial<Task>) => void;
  deleteTask: (id: string) => void;
}

const TaskContext = createContext<TaskContextType | undefined>(undefined);

export function TaskProvider({ children }: { children: React.ReactNode }) {
  const [tasks, setTasks] = useState<Task[]>([]);

  const addTask = (task: Task) => {
    setTasks(prev => [...prev, task]);
  };

  const updateTask = (id: string, updates: Partial<Task>) => {
    setTasks(prev => prev.map(t => t.id === id ? { ...t, ...updates } : t));
  };

  const deleteTask = (id: string) => {
    setTasks(prev => prev.filter(t => t.id !== id));
  };

  return (
    <TaskContext.Provider value={{ tasks, addTask, updateTask, deleteTask }}>
      {children}
    </TaskContext.Provider>
  );
}

export const useTasks = () => {
  const context = useContext(TaskContext);
  if (!context) {
    throw new Error('useTasks must be used within TaskProvider');
  }
  return context;
};
```

## Code Standards

### JavaScript/TypeScript

- Use ESLint and Prettier
- Follow Airbnb style guide
- Use TypeScript for type safety
- Prefer functional components
- Use async/await over promises

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/task-filters

# Make changes
git add .
git commit -m "feat: add task filtering by status"

# Push and create PR
git push origin feature/task-filters
```

**Commit Message Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

### Code Review Checklist

See [Code Review Summary](REVIEW_COMPLETE.md) for comprehensive review results.

- [ ] Code follows style guide
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No hardcoded values
- [ ] Error handling implemented
- [ ] Security considerations addressed
- [ ] Performance optimized

## Testing

### Unit Tests

```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run specific test
npm test -- task.test.js

# Watch mode
npm test -- --watch
```

### Integration Tests

```bash
# Run integration tests
npm run test:integration

# Test API endpoints
cd tests/integration
npm test
```

### E2E Tests

```bash
# Install Playwright
cd tests/e2e
npm install

# Run E2E tests
npm run test:e2e

# Run in headed mode
npm run test:e2e -- --headed

# Debug mode
npm run test:e2e -- --debug
```

### Test Coverage

```bash
# Generate coverage report
npm test -- --coverage --coverageDirectory=coverage

# View coverage report
open coverage/lcov-report/index.html
```

## Debugging

### VS Code Debug Configuration

```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Lambda Function",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/lambda/task-api/index.js",
      "env": {
        "AWS_REGION": "eu-west-1",
        "DYNAMODB_TABLE": "task-manager-sandbox-main"
      }
    },
    {
      "name": "Debug Frontend",
      "type": "node",
      "request": "launch",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "port": 9229,
      "cwd": "${workspaceFolder}/frontend"
    }
  ]
}
```

### CloudWatch Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow

# Filter logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/task-manager-sandbox-task-api \
  --filter-pattern "ERROR"
```

## Performance Optimization

### Lambda Optimization

- Use provisioned concurrency for critical functions
- Optimize cold start time
- Use layers for dependencies
- Enable X-Ray tracing

### Frontend Optimization

- Use Next.js image optimization
- Implement code splitting
- Use React.memo for expensive components
- Lazy load components

## Additional Resources

- [Code Review Summary](CODE_REVIEW_SUMMARY.md)
- [Review Complete](REVIEW_COMPLETE.md)
- [Architecture Guide](../architecture/README.md)
- [API Documentation](../api/README.md)

---

**Last Updated**: February 2026
