# API Documentation

Complete API reference for the AWS Serverless Task Manager.

## 📋 Table of Contents

- [API Overview](#api-overview)
- [Authentication](#authentication)
- [REST API](#rest-api)
- [GraphQL API](#graphql-api)
- [Notifications](#notifications)
- [Webhooks](#webhooks)

## API Overview

The Task Manager provides two API interfaces:

1. **REST API** - Traditional HTTP endpoints via API Gateway
2. **GraphQL API** - Flexible queries via AWS AppSync

Both APIs require authentication and support role-based access control.

### Base URLs

```
# REST API
Production:  https://api.taskmanager.example.com
Staging:     https://api.staging.taskmanager.example.com
Sandbox:     https://api.sandbox.taskmanager.example.com

# GraphQL API (AppSync)
Production:  https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql
Staging:     https://yyyyy.appsync-api.eu-west-1.amazonaws.com/graphql
Sandbox:     https://zzzzz.appsync-api.eu-west-1.amazonaws.com/graphql
```

## Authentication

### Getting an Access Token

```bash
# Using AWS Cognito
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id YOUR_CLIENT_ID \
  --auth-parameters \
    USERNAME=user@example.com,PASSWORD=YourPassword123!

# Response includes:
# - AccessToken (for API calls)
# - IdToken (user identity)
# - RefreshToken (for token renewal)
```

### Using the Token

```bash
# REST API
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  https://api.taskmanager.example.com/tasks

# GraphQL API
curl -X POST \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ getMyTasks { id title } }"}' \
  https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql
```

## REST API

Complete reference: [API Documentation](API_DOCUMENTATION.md)

### Tasks

#### List Tasks
```http
GET /tasks
Authorization: Bearer {token}

Query Parameters:
  - status: Filter by status (TODO, IN_PROGRESS, DONE)
  - project: Filter by project ID
  - assigned: Filter by assignee ID
  - limit: Number of results (default: 20)
  - cursor: Pagination cursor

Response: 200 OK
{
  "tasks": [...],
  "nextCursor": "..."
}
```

#### Get Task
```http
GET /tasks/{taskId}
Authorization: Bearer {token}

Response: 200 OK
{
  "id": "task-123",
  "title": "Implement feature",
  "description": "...",
  "status": "IN_PROGRESS",
  "priority": "HIGH",
  "assignedTo": "user-456",
  "projectId": "project-789",
  "createdAt": "2026-02-12T10:00:00Z",
  "updatedAt": "2026-02-12T14:30:00Z"
}
```

#### Create Task
```http
POST /tasks
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "New task",
  "description": "Task description",
  "priority": "MEDIUM",
  "projectId": "project-789",
  "assignedTo": "user-456",
  "dueDate": "2026-02-20T23:59:59Z"
}

Response: 201 Created
{
  "id": "task-123",
  ...
}
```

#### Update Task
```http
PUT /tasks/{taskId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "DONE",
  "completedAt": "2026-02-12T15:00:00Z"
}

Response: 200 OK
```

#### Delete Task
```http
DELETE /tasks/{taskId}
Authorization: Bearer {token}

Response: 204 No Content
```

### Users

#### List Users
```http
GET /users
Authorization: Bearer {token}

Response: 200 OK
{
  "users": [
    {
      "id": "user-123",
      "email": "user@example.com",
      "name": "John Doe",
      "role": "Member",
      "enabled": true
    }
  ]
}
```

#### Get User
```http
GET /users/{userId}
Authorization: Bearer {token}

Response: 200 OK
```

### Projects

#### List Projects
```http
GET /projects
Authorization: Bearer {token}

Response: 200 OK
{
  "projects": [...]
}
```

#### Create Project
```http
POST /projects
Authorization: Bearer {token}

{
  "name": "New Project",
  "description": "Project description",
  "teamMembers": ["user-123", "user-456"]
}

Response: 201 Created
```

### File Uploads

#### Get Upload URL
```http
POST /files/upload-url
Authorization: Bearer {token}

{
  "fileName": "document.pdf",
  "contentType": "application/pdf",
  "taskId": "task-123"
}

Response: 200 OK
{
  "uploadUrl": "https://s3.amazonaws.com/...",
  "fileId": "file-789",
  "expiresIn": 3600
}
```

#### Get Download URL
```http
GET /files/{fileId}/download-url
Authorization: Bearer {token}

Response: 200 OK
{
  "downloadUrl": "https://s3.amazonaws.com/...",
  "expiresIn": 3600
}
```

## GraphQL API

### Schema

```graphql
type Task {
  id: ID!
  title: String!
  description: String
  status: TaskStatus!
  priority: Priority!
  assignedTo: User
  project: Project
  createdBy: User!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
  dueDate: AWSDateTime
  completedAt: AWSDateTime
  comments: [Comment]
  attachments: [Attachment]
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  DONE
  CANCELLED
}

enum Priority {
  LOW
  MEDIUM
  HIGH
  URGENT
}

type Query {
  getTask(id: ID!): Task
  listTasks(filter: TaskFilterInput, limit: Int, nextToken: String): TaskConnection
  getMyTasks: [Task]
  searchTasks(query: String!): [Task]
  
  getProject(id: ID!): Project
  listProjects: [Project]
  
  getUser(id: ID!): User
  listUsers: [User]
}

type Mutation {
  createTask(input: CreateTaskInput!): Task
  updateTask(id: ID!, input: UpdateTaskInput!): Task
  deleteTask(id: ID!): Boolean
  
  assignTask(taskId: ID!, userId: ID!): Task
  unassignTask(taskId: ID!): Task
  
  addComment(taskId: ID!, text: String!): Comment
  
  createProject(input: CreateProjectInput!): Project
  updateProject(id: ID!, input: UpdateProjectInput!): Project
}

type Subscription {
  onTaskUpdated(id: ID!): Task
  onMyTasksUpdated: Task
  onProjectTasksUpdated(projectId: ID!): Task
}
```

### Example Queries

```graphql
# Get my tasks
query GetMyTasks {
  getMyTasks {
    id
    title
    status
    priority
    dueDate
    project {
      id
      name
    }
  }
}

# Search tasks
query SearchTasks($query: String!) {
  searchTasks(query: $query) {
    id
    title
    description
    status
  }
}

# Get task with details
query GetTask($id: ID!) {
  getTask(id: $id) {
    id
    title
    description
    status
    priority
    assignedTo {
      id
      name
      email
    }
    comments {
      id
      text
      createdBy {
        name
      }
      createdAt
    }
    attachments {
      id
      fileName
      url
    }
  }
}
```

### Example Mutations

```graphql
# Create task
mutation CreateTask($input: CreateTaskInput!) {
  createTask(input: $input) {
    id
    title
    status
  }
}

# Variables:
{
  "input": {
    "title": "New feature",
    "description": "...",
    "priority": "HIGH",
    "projectId": "project-123"
  }
}

# Update task status
mutation UpdateTaskStatus($id: ID!, $status: TaskStatus!) {
  updateTask(id: $id, input: { status: $status }) {
    id
    status
    updatedAt
  }
}

# Add comment
mutation AddComment($taskId: ID!, $text: String!) {
  addComment(taskId: $taskId, text: $text) {
    id
    text
    createdAt
  }
}
```

### Subscriptions

```graphql
# Subscribe to task updates
subscription OnTaskUpdated($id: ID!) {
  onTaskUpdated(id: $id) {
    id
    title
    status
    updatedAt
  }
}

# Subscribe to my tasks
subscription OnMyTasksUpdated {
  onMyTasksUpdated {
    id
    title
    status
  }
}
```

## Notifications

### Automatic Notifications

See [Auto Notifications](AUTO_NOTIFICATIONS.md) and [Member Notifications](MEMBER_NOTIFICATIONS.md) for details.

**Events that trigger notifications**:
- Task assigned to user
- Task status changed
- Task comment added
- Task due date approaching
- Project milestone reached

### Notification Preferences

```http
GET /users/{userId}/notification-preferences
Authorization: Bearer {token}

Response: 200 OK
{
  "email": true,
  "inApp": true,
  "taskAssigned": true,
  "taskUpdated": true,
  "comments": true,
  "dueDateReminders": true
}
```

```http
PUT /users/{userId}/notification-preferences
Authorization: Bearer {token}

{
  "email": false,
  "taskUpdated": false
}

Response: 200 OK
```

## Webhooks

### GitHub Integration

See [SNS Migration](SNS_MIGRATION.md) for webhook configuration.

#### Register Webhook
```http
POST /webhooks/github
Authorization: Bearer {token}

{
  "url": "https://api.github.com/repos/owner/repo/hooks",
  "events": ["push", "pull_request"],
  "secret": "webhook-secret"
}

Response: 201 Created
{
  "id": "webhook-123",
  "url": "...",
  "active": true
}
```

#### Webhook Payload
```json
{
  "event": "task.created",
  "timestamp": "2026-02-12T10:00:00Z",
  "data": {
    "id": "task-123",
    "title": "New task",
    "status": "TODO",
    "assignedTo": "user-456"
  },
  "signature": "sha256=..."
}
```

### Custom Webhooks

```http
POST /webhooks
Authorization: Bearer {token}

{
  "url": "https://your-app.com/webhooks",
  "events": ["task.created", "task.updated", "task.completed"],
  "secret": "your-webhook-secret"
}
```

## Rate Limiting

API requests are rate limited per user:

- **Default**: 100 requests per minute
- **Burst**: 200 requests per minute
- **Daily**: 10,000 requests per day

**Rate Limit Headers**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1644667200
```

**Rate Limit Exceeded**:
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "error": "Rate limit exceeded",
  "retryAfter": 60
}
```

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      {
        "field": "title",
        "message": "Title is required"
      }
    ]
  },
  "requestId": "req-12345"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource conflict |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

## Testing APIs

### Using cURL

```bash
# Set token
TOKEN="your-access-token"

# List tasks
curl -H "Authorization: Bearer $TOKEN" \
  https://api.taskmanager.example.com/tasks

# Create task
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"New task","priority":"HIGH"}' \
  https://api.taskmanager.example.com/tasks
```

### Using Postman

1. Import collection from `docs/api/postman-collection.json`
2. Set environment variables:
   - `base_url`
   - `access_token`
   - `user_id`
3. Run requests

### Using GraphQL Playground

1. Open AppSync Console
2. Navigate to Queries
3. Set Authorization header
4. Run queries interactively

## SDK Usage

### JavaScript/TypeScript

```typescript
import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/api';

// Configure Amplify
Amplify.configure({
  API: {
    GraphQL: {
      endpoint: process.env.APPSYNC_URL,
      region: 'eu-west-1',
      defaultAuthMode: 'userPool'
    }
  }
});

const client = generateClient();

// Query tasks
const { data } = await client.graphql({
  query: queries.listTasks
});

// Create task
const newTask = await client.graphql({
  query: mutations.createTask,
  variables: {
    input: {
      title: 'New task',
      priority: 'HIGH'
    }
  }
});
```

## Additional Resources

- [API Documentation](API_DOCUMENTATION.md) - Complete REST API reference
- [Auto Notifications](AUTO_NOTIFICATIONS.md) - Notification system details
- [Member Notifications](MEMBER_NOTIFICATIONS.md) - User notification preferences
- [SNS Migration](SNS_MIGRATION.md) - Webhook and event system

---

**Last Updated**: February 2026  
**API Version**: v1
