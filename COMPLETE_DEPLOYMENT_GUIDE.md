# Complete Deployment Guide: Terraform to Amplify

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Infrastructure Layer (Terraform)](#infrastructure-layer-terraform)
3. [Lambda Functions](#lambda-functions)
4. [Frontend Deployment (Amplify)](#frontend-deployment-amplify)
5. [Integration Flow](#integration-flow)
6. [Deployment Process](#deployment-process)
7. [Environment Configuration](#environment-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Frontend Layer                           │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Amplify Hosting (Next.js 14 + TypeScript)          │  │ │
│  │  │  - Server-side rendering                            │  │ │
│  │  │  - Static optimization                              │  │ │
│  │  │  - CI/CD via GitHub integration                     │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     API Gateway Layer                       │ │
│  │  ┌────────────────┐     ┌────────────────────────────┐    │ │
│  │  │  AppSync       │     │  API Gateway (REST)        │    │ │
│  │  │  (GraphQL)     │     │  - /tasks                  │    │ │
│  │  │                │     │  - /users                  │    │ │
│  │  └────────────────┘     └────────────────────────────┘    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 Authentication Layer                        │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  Amazon Cognito                                     │  │ │
│  │  │  - User pools                                       │  │ │
│  │  │  - Groups: Admins, Members                         │  │ │
│  │  │  - JWT token validation                            │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Compute Layer                            │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  AWS Lambda Functions (Node.js 18)                 │  │ │
│  │  │                                                      │  │ │
│  │  │  ├─ pre-signup-trigger     (Cognito pre-signup)    │  │ │
│  │  │  ├─ task-api              (REST API operations)    │  │ │
│  │  │  ├─ users-api             (User management)        │  │ │
│  │  │  ├─ appsync-resolver      (GraphQL resolvers)      │  │ │
│  │  │  ├─ notification-handler  (Email notifications)    │  │ │
│  │  │  ├─ stream-processor      (DynamoDB → OpenSearch) │  │ │
│  │  │  ├─ file-processor        (S3 file handling)       │  │ │
│  │  │  ├─ presigned-url         (S3 URL generation)      │  │ │
│  │  │  └─ github-webhook        (GitHub integration)     │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                     Data Layer                              │ │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐   │ │
│  │  │ DynamoDB   │  │ S3 Bucket  │  │ OpenSearch         │   │ │
│  │  │ (Tasks)    │  │ (Files)    │  │ (Full-text search) │   │ │
│  │  └────────────┘  └────────────┘  └────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                Event & Notification Layer                   │ │
│  │  ┌────────────────┐  ┌─────────┐  ┌────────────────────┐  │ │
│  │  │  EventBridge   │  │   SNS   │  │   SES (Email)      │  │ │
│  │  │  (Event bus)   │  │ (Topics)│  │                    │  │ │
│  │  └────────────────┘  └─────────┘  └────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              ↓                                    │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                  Monitoring & Logging                       │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │  CloudWatch                                         │  │ │
│  │  │  - Logs (30-day retention)                         │  │ │
│  │  │  - Alarms (API, Lambda, DynamoDB)                  │  │ │
│  │  │  - X-Ray tracing                                   │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Frontend:**
- Next.js 14 with App Router
- TypeScript for type safety
- Tailwind CSS for styling
- Amplify UI components
- React Query for data fetching

**Backend:**
- AWS Lambda (Node.js 18.x)
- API Gateway (REST)
- AppSync (GraphQL)
- DynamoDB (single-table design)

**Infrastructure:**
- Terraform (Infrastructure as Code)
- GitHub Actions (CI/CD)
- AWS Amplify (Frontend hosting)

---

## Infrastructure Layer (Terraform)

### Terraform Project Structure

```
terraform/
├── main.tf                    # Root configuration, orchestrates all modules
├── variables.tf               # Input variables for all environments
├── outputs.tf                 # Exported values (API URLs, ARNs, etc.)
├── provider.tf                # AWS provider configuration
├── backend.tf                 # S3 backend for state management
├── terraform.tfvars           # Default variable values
├── environments/              # Environment-specific configurations
│   ├── sandbox.tfvars        # Development environment
│   ├── staging.tfvars        # Pre-production environment
│   └── production.tfvars     # Production environment
└── modules/                   # Reusable infrastructure modules
    ├── dynamodb/             # DynamoDB table with streams
    ├── cognito/              # User authentication
    ├── lambda/               # All Lambda functions
    ├── api-gateway/          # REST API
    ├── appsync/              # GraphQL API
    ├── s3/                   # File storage
    ├── eventbridge/          # Event bus
    ├── sns/                  # Notifications
    ├── ses/                  # Email service
    ├── opensearch/           # Search service
    └── cloudwatch-alarms/    # Monitoring
```

### Module Breakdown

#### 1. DynamoDB Module (`modules/dynamodb/`)

**Purpose:** Single-table design for all application data

**Resources Created:**
```hcl
resource "aws_dynamodb_table" "tasks" {
  name           = "task-manager-${var.environment}-tasks"
  billing_mode   = "PAY_PER_REQUEST"  # Auto-scaling
  hash_key       = "PK"                # Partition key
  range_key      = "SK"                # Sort key
  
  # Enable DynamoDB Streams for real-time data sync
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  # Point-in-time recovery for production
  point_in_time_recovery {
    enabled = var.environment == "production"
  }
}
```

**Access Patterns:**
- `PK=TASK#<taskId>`, `SK=METADATA` → Task details
- `PK=PROJECT#<projectId>`, `SK=TASK#<taskId>` → Tasks in project
- `PK=USER#<userId>`, `SK=TASK#<taskId>` → User's tasks
- `PK=SPRINT#<sprintId>`, `SK=TASK#<taskId>` → Sprint tasks
- `PK=TASK#<taskId>`, `SK=COMMENT#<timestamp>` → Task comments

**GSI Indexes:**
1. `GSI1` - Status/assignee queries
2. `GSI2` - Due date queries
3. `GSI3` - Priority queries

#### 2. Cognito Module (`modules/cognito/`)

**Purpose:** User authentication and authorization

**Resources Created:**
```hcl
# User Pool
resource "aws_cognito_user_pool" "main" {
  name = "task-manager-${var.environment}"
  
  # Email as username
  username_attributes = ["email"]
  
  # Password policy
  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
  
  # Email verification
  auto_verified_attributes = ["email"]
  
  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  
  # Pre-signup Lambda trigger
  lambda_config {
    pre_sign_up = var.pre_signup_lambda_arn
  }
}

# User Groups
resource "aws_cognito_user_group" "admins" {
  name         = "Admins"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators with full access"
}

resource "aws_cognito_user_group" "members" {
  name         = "Members"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Regular team members"
}

# App Client
resource "aws_cognito_user_pool_client" "web" {
  name         = "web-client"
  user_pool_id = aws_cognito_user_pool.main.id
  
  # OAuth settings
  allowed_oauth_flows  = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  callback_urls        = var.callback_urls
  logout_urls          = var.logout_urls
  
  # Token validity
  id_token_validity     = 60  # minutes
  access_token_validity = 60
  refresh_token_validity = 30 # days
}
```

**User Flow:**
1. User signs up → triggers `pre-signup-trigger` Lambda
2. Lambda validates email domain (@amalitech.com, @amalitechtraining.org)
3. User confirms email
4. User added to "Members" group by default
5. Admin can promote to "Admins" group via script

#### 3. Lambda Module (`modules/lambda/`)

**Purpose:** All compute functions with automated deployment

**Key Features:**
- Automated building via `null_resource`
- Change detection with file hashes
- Shared Lambda layer for common dependencies
- IAM roles with least-privilege policies
- CloudWatch logs with 30-day retention
- X-Ray tracing enabled

**Automated Build System:**
```hcl
resource "null_resource" "build_lambdas" {
  triggers = {
    # Rebuild when source code changes
    pre_signup_trigger   = filesha256("${path.module}/../../../lambda/pre-signup-trigger/index.js")
    task_api            = filesha256("${path.module}/../../../lambda/task-api/index.js")
    users_api           = filesha256("${path.module}/../../../lambda/users-api/index.js")
    notification_handler = filesha256("${path.module}/../../../lambda/notification-handler/index.js")
    appsync_resolver    = filesha256("${path.module}/../../../lambda/appsync-resolver/index.js")
    stream_processor    = filesha256("${path.module}/../../../lambda/stream-processor/index.js")
    file_processor      = filesha256("${path.module}/../../../lambda/file-processor/index.js")
    presigned_url       = filesha256("${path.module}/../../../lambda/presigned-url/index.js")
    github_webhook      = filesha256("${path.module}/../../../lambda/github-webhook/index.js")
    build_script        = filesha256("${path.module}/../../../scripts/build-lambdas.sh")
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/../../../scripts/build-lambdas.sh"
    working_dir = path.module
  }
}
```

**Lambda Functions Explained:**

1. **pre-signup-trigger** (Cognito Trigger)
   - **Trigger:** User registration
   - **Purpose:** Email domain validation
   - **Logic:** Allow only @amalitech.com or @amalitechtraining.org emails
   - **Response:** Auto-confirms valid users

2. **task-api** (REST API)
   - **Endpoint:** `/tasks/*`
   - **Operations:** CRUD operations on tasks
   - **Permissions:** DynamoDB read/write, EventBridge publish
   - **Returns:** Task objects with metadata

3. **users-api** (REST API)
   - **Endpoint:** `/users/*`
   - **Purpose:** User management and listing
   - **Permissions:** Cognito read-only
   - **Returns:** User list with groups and status

4. **appsync-resolver** (GraphQL)
   - **Purpose:** Handles all GraphQL queries/mutations
   - **Permissions:** DynamoDB, EventBridge, Cognito
   - **Resolvers:** 40+ GraphQL operations

5. **notification-handler** (EventBridge Target)
   - **Trigger:** EventBridge events (task updates, assignments)
   - **Purpose:** Send email notifications via SNS
   - **Logic:** Fetch user data, format email, publish to SNS

6. **stream-processor** (DynamoDB Stream)
   - **Trigger:** DynamoDB record changes
   - **Purpose:** Index data in OpenSearch for search
   - **Logic:** Transform DynamoDB records → OpenSearch documents

7. **file-processor** (S3 Event)
   - **Trigger:** S3 object creation
   - **Purpose:** Validate, resize images, extract metadata
   - **Permissions:** S3 read/write, DynamoDB write

8. **presigned-url** (AppSync Resolver)
   - **Purpose:** Generate secure S3 upload/download URLs
   - **Security:** Time-limited (1 hour), scoped to user
   - **Returns:** Pre-signed URL with CORS headers

9. **github-webhook** (API Gateway)
   - **Endpoint:** `/webhook/github`
   - **Purpose:** Sync GitHub events to tasks
   - **Security:** HMAC signature verification
   - **Events:** Push, PR, PR review

**Lambda Layer (Shared Dependencies):**
```javascript
// Shared across all functions
- aws-sdk (DynamoDB, S3, Cognito clients)
- Common utilities (logging, validation)
- Error handling middleware
```

#### 4. API Gateway Module (`modules/api-gateway/`)

**Purpose:** REST API for task operations

**Configuration:**
```hcl
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.api_name}"
  description = "Task Manager REST API"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "cognito"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# Resources & Methods
resource "aws_api_gateway_resource" "tasks" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "tasks"
}

# Throttling (DDoS protection)
resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"
  
  settings {
    throttling_rate_limit  = var.throttle_rate_limit  # 1000 req/sec
    throttling_burst_limit = var.throttle_burst_limit # 2000 burst
  }
}
```

**Endpoints:**
```
GET    /tasks              → List all tasks
POST   /tasks              → Create task
GET    /tasks/{id}         → Get task details
PUT    /tasks/{id}         → Update task
DELETE /tasks/{id}         → Delete task
POST   /tasks/{id}/assign  → Assign task
GET    /users              → List users
```

#### 5. AppSync Module (`modules/appsync/`)

**Purpose:** GraphQL API for real-time operations

**Configuration:**
```hcl
resource "aws_appsync_graphql_api" "main" {
  name                = var.api_name
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  
  user_pool_config {
    aws_region     = var.aws_region
    default_action = "ALLOW"
    user_pool_id   = var.cognito_user_pool_id
  }
  
  # Additional IAM auth for server-to-server
  additional_authentication_provider {
    authentication_type = "AWS_IAM"
  }
  
  # Enable X-Ray tracing
  xray_enabled = true
  
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync_logs.arn
    field_log_level          = "ERROR"
  }
}

# Lambda Data Source (handles most operations)
resource "aws_appsync_datasource" "lambda" {
  api_id           = aws_appsync_graphql_api.main.id
  name             = "LambdaDataSource"
  service_role_arn = aws_iam_role.appsync_lambda.arn
  type             = "AWS_LAMBDA"
  
  lambda_config {
    function_arn = var.resolver_lambda_arn
  }
}
```

**GraphQL Schema Highlights:**
```graphql
type Task {
  taskId: ID!
  title: String!
  description: String
  status: TaskStatus!
  priority: Priority!
  assignedTo: [String!]
  dueDate: AWSDateTime
  projectId: String
  sprintId: String
  tags: [String!]
  attachments: [Attachment!]
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type Query {
  getTask(taskId: ID!): Task
  listTasks(filter: TaskFilter, limit: Int, nextToken: String): TaskConnection
  getMyTasks: [Task!]!
  searchTasks(query: String!): [Task!]!
  getProject(projectId: ID!): Project
  listProjects: [Project!]!
}

type Mutation {
  createTask(input: CreateTaskInput!): Task
  updateTask(taskId: ID!, input: UpdateTaskInput!): Task
  deleteTask(taskId: ID!): Boolean
  assignTask(taskId: ID!, userId: String!): Task
  unassignTask(taskId: ID!, userId: String!): Task
  addComment(taskId: ID!, content: String!): Comment
}

type Subscription {
  onTaskUpdate(taskId: ID!): Task
    @aws_subscribe(mutations: ["updateTask"])
  onTaskCreated(projectId: String): Task
    @aws_subscribe(mutations: ["createTask"])
}
```

#### 6. S3 Module (`modules/s3/`)

**Purpose:** File storage for task attachments

**Configuration:**
```hcl
resource "aws_s3_bucket" "attachments" {
  bucket = "${var.name_prefix}-attachments"
}

# Block public access
resource "aws_s3_bucket_public_access_block" "attachments" {
  bucket                  = aws_s3_bucket.attachments.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy (delete old files)
resource "aws_s3_bucket_lifecycle_configuration" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  
  rule {
    id     = "delete-old-attachments"
    status = "Enabled"
    
    expiration {
      days = 90  # Delete after 90 days
    }
  }
}

# Event notification for file processing
resource "aws_s3_bucket_notification" "attachments" {
  bucket = aws_s3_bucket.attachments.id
  
  lambda_function {
    lambda_function_arn = var.file_processor_lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }
}
```

**File Upload Flow:**
1. Frontend requests presigned URL from `presigned-url` Lambda
2. Frontend uploads file directly to S3 (bypasses Lambda 6MB limit)
3. S3 triggers `file-processor` Lambda
4. Lambda validates file, extracts metadata, stores in DynamoDB
5. Frontend polls for processing completion

#### 7. EventBridge Module (`modules/eventbridge/`)

**Purpose:** Event-driven architecture for decoupling

**Configuration:**
```hcl
resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.name_prefix}-event-bus"
}

# Rule: Task assignments → Send notifications
resource "aws_cloudwatch_event_rule" "task_assigned" {
  name           = "${var.name_prefix}-task-assigned"
  description    = "Trigger when task is assigned"
  event_bus_name = aws_cloudwatch_event_bus.main.name
  
  event_pattern = jsonencode({
    source      = ["task-manager"]
    detail-type = ["Task Assigned"]
  })
}

resource "aws_cloudwatch_event_target" "notification_handler" {
  rule           = aws_cloudwatch_event_rule.task_assigned.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  arn            = var.notification_handler_lambda_arn
}
```

**Event Types:**
- `Task Created`
- `Task Updated`
- `Task Assigned`
- `Task Completed`
- `Comment Added`
- `Sprint Started`
- `Sprint Completed`

#### 8. SNS Module (`modules/sns/`)

**Purpose:** Email notifications

**Configuration:**
```hcl
resource "aws_sns_topic" "notifications" {
  name = "${var.name_prefix}-notifications"
}

# Email subscriptions
resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.notification_emails)
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = each.value
}
```

**Notification Flow:**
1. Event triggers Lambda
2. Lambda formats email content
3. Lambda publishes to SNS topic
4. SNS sends email to all subscribers

---

## Lambda Functions

### Development Structure

```
lambda/
├── layers/
│   └── shared-layer/          # Common dependencies
│       ├── package.json
│       ├── node_modules/
│       └── shared-layer.zip   # Built by Terraform
│
├── pre-signup-trigger/
│   ├── index.js               # Handler code
│   ├── package.json           # Dependencies
│   └── function.zip           # Deployment package
│
├── task-api/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
├── users-api/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
├── appsync-resolver/
│   ├── index.js
│   ├── resolvers/             # GraphQL resolvers
│   │   ├── queries.js
│   │   └── mutations.js
│   ├── package.json
│   └── function.zip
│
├── notification-handler/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
├── stream-processor/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
├── file-processor/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
├── presigned-url/
│   ├── index.js
│   ├── package.json
│   └── function.zip
│
└── github-webhook/
    ├── index.js
    ├── package.json
    └── function.zip
```

### Build Process

**Script:** `scripts/build-lambdas.sh`

```bash
#!/bin/bash
# Builds all Lambda deployment packages

# For each Lambda function:
1. cd lambda/<function-name>
2. npm install --production        # Install dependencies
3. zip -r function.zip .           # Package everything
4. Verify ZIP size < 50MB          # AWS limit
```

**Terraform Integration:**
```hcl
# Terraform automatically:
1. Triggers build when source changes (via null_resource)
2. Uploads ZIP files to Lambda
3. Updates function code
4. Waits for deployment to complete
```

### Environment Variables

Each Lambda receives environment variables from Terraform:

```javascript
// Example: task-api function
process.env.TABLE_NAME      // DynamoDB table name
process.env.EVENT_BUS_NAME  // EventBridge bus name
process.env.USER_POOL_ID    // Cognito pool ID
process.env.AWS_REGION      // AWS region
```

**Configured via Terraform:**
```hcl
resource "aws_lambda_function" "task_api" {
  # ... other config ...
  
  environment {
    variables = {
      TABLE_NAME     = var.dynamodb_table_name
      EVENT_BUS_NAME = var.eventbridge_bus_name
      USER_POOL_ID   = var.cognito_user_pool_id
      AWS_REGION     = var.aws_region
    }
  }
}
```

---

## Frontend Deployment (Amplify)

### Amplify Project Structure

```
frontend/
├── app/                       # Next.js App Router
│   ├── page.tsx              # Home page
│   ├── layout.tsx            # Root layout
│   ├── (auth)/               # Auth pages
│   │   ├── login/
│   │   └── register/
│   ├── (dashboard)/          # Protected routes
│   │   ├── tasks/
│   │   ├── projects/
│   │   └── sprints/
│   └── api/                  # API routes
│
├── components/               # React components
│   ├── ui/                  # shadcn/ui components
│   ├── tasks/               # Task components
│   ├── projects/            # Project components
│   └── layout/              # Layout components
│
├── lib/                     # Utilities
│   ├── auth.ts             # Authentication helpers
│   ├── api.ts              # API client
│   ├── graphql.ts          # GraphQL queries
│   └── utils.ts            # Common utilities
│
├── public/                  # Static assets
│   ├── images/
│   └── icons/
│
├── amplify/                 # Amplify configuration
│   ├── backend/            # Backend resources
│   │   └── api/
│   └── team-provider-info.json
│
├── .env.local              # Local development
├── .env.production         # Production config (created by deploy script)
├── amplify.yml             # Build specification
├── next.config.js          # Next.js configuration
├── package.json            # Dependencies
└── tsconfig.json           # TypeScript config
```

### Amplify Configuration

**amplify.yml** (Build specification):
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
      - .next/cache/**/*

env:
  variables:
    # Backend endpoints (from Terraform outputs)
    NEXT_PUBLIC_API_URL: ${API_URL}
    NEXT_PUBLIC_APPSYNC_URL: ${APPSYNC_URL}
    NEXT_PUBLIC_COGNITO_USER_POOL_ID: ${USER_POOL_ID}
    NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID: ${CLIENT_ID}
    NEXT_PUBLIC_AWS_REGION: ${AWS_REGION}
```

### Amplify Deployment Process

**Manual Setup (First Time):**
```bash
# 1. Install Amplify CLI
npm install -g @aws-amplify/cli

# 2. Configure Amplify
amplify configure

# 3. Initialize project
cd frontend
amplify init

# 4. Add hosting
amplify add hosting

# 5. Deploy
amplify publish
```

**Automated Deployment (Recommended):**

1. **Connect GitHub Repository:**
   - Open AWS Amplify Console
   - Select "Host web app"
   - Connect GitHub repository
   - Select branch (main → production, develop → staging)

2. **Configure Environment Variables:**
   ```bash
   # Run deployment script to extract Terraform outputs
   ./scripts/deploy.sh --frontend-only
   
   # Or manually in Amplify Console:
   # Environment → Environment variables
   NEXT_PUBLIC_API_URL=<from terraform output>
   NEXT_PUBLIC_APPSYNC_URL=<from terraform output>
   NEXT_PUBLIC_COGNITO_USER_POOL_ID=<from terraform output>
   NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID=<from terraform output>
   NEXT_PUBLIC_AWS_REGION=eu-west-1
   ```

3. **Deploy:**
   - Push to GitHub
   - Amplify automatically builds and deploys
   - Build takes ~5-7 minutes

**Build Logs:**
```
Provisioning ✓
Cloning repository ✓
Installing dependencies ✓
Building application ✓
Deploying ✓
```

### Frontend Integration with Backend

**1. Authentication (Cognito):**
```typescript
// lib/auth.ts
import { Amplify, Auth } from 'aws-amplify';

Amplify.configure({
  Auth: {
    region: process.env.NEXT_PUBLIC_AWS_REGION,
    userPoolId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID,
    userPoolWebClientId: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID,
  }
});

// Sign in
const user = await Auth.signIn(email, password);

// Get JWT token
const session = await Auth.currentSession();
const token = session.getIdToken().getJwtToken();

// Sign out
await Auth.signOut();
```

**2. REST API Calls:**
```typescript
// lib/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL,
});

// Add auth header to all requests
api.interceptors.request.use(async (config) => {
  const session = await Auth.currentSession();
  config.headers.Authorization = session.getIdToken().getJwtToken();
  return config;
});

// Fetch tasks
const tasks = await api.get('/tasks');

// Create task
const task = await api.post('/tasks', {
  title: 'New task',
  description: 'Task description',
  status: 'TODO',
  priority: 'HIGH'
});
```

**3. GraphQL Operations:**
```typescript
// lib/graphql.ts
import { generateClient } from 'aws-amplify/api';
import { Amplify } from 'aws-amplify';

Amplify.configure({
  API: {
    GraphQL: {
      endpoint: process.env.NEXT_PUBLIC_APPSYNC_URL,
      region: process.env.NEXT_PUBLIC_AWS_REGION,
      defaultAuthMode: 'userPool'
    }
  }
});

const client = generateClient();

// Query
const result = await client.graphql({
  query: `
    query ListTasks {
      listTasks {
        items {
          taskId
          title
          status
          priority
        }
      }
    }
  `
});

// Mutation
const task = await client.graphql({
  query: `
    mutation CreateTask($input: CreateTaskInput!) {
      createTask(input: $input) {
        taskId
        title
        status
      }
    }
  `,
  variables: {
    input: {
      title: 'New task',
      status: 'TODO',
      priority: 'HIGH'
    }
  }
});

// Subscription (real-time updates)
const subscription = client.graphql({
  query: `
    subscription OnTaskUpdate($taskId: ID!) {
      onTaskUpdate(taskId: $taskId) {
        taskId
        title
        status
        updatedAt
      }
    }
  `,
  variables: { taskId: '123' }
}).subscribe({
  next: ({ data }) => console.log('Task updated:', data),
  error: (error) => console.error('Subscription error:', error)
});
```

**4. File Uploads:**
```typescript
// Upload file to S3 via presigned URL
async function uploadFile(file: File, taskId: string) {
  // 1. Get presigned URL from Lambda
  const { url, key } = await client.graphql({
    query: `
      mutation GetUploadUrl($input: GetUploadUrlInput!) {
        getPresignedUploadUrl(
          fileName: $input.fileName,
          fileType: $input.fileType,
          taskId: $input.taskId
        ) {
          url
          key
        }
      }
    `,
    variables: {
      input: {
        fileName: file.name,
        fileType: file.type,
        taskId
      }
    }
  });
  
  // 2. Upload directly to S3
  await fetch(url, {
    method: 'PUT',
    body: file,
    headers: {
      'Content-Type': file.type
    }
  });
  
  // 3. File is now in S3, Lambda will process it
  return key;
}
```

---

## Integration Flow

### Complete Request Flow Example

**Scenario:** User creates a new task

```
┌──────────┐
│  Browser │
└────┬─────┘
     │ 1. User fills task form, clicks "Create"
     │
     ▼
┌──────────────────┐
│   Next.js App    │
│  (Frontend)      │
└────┬─────────────┘
     │ 2. Form validation passes
     │ 3. Get JWT token from Cognito session
     │
     ▼
┌──────────────────┐
│   GraphQL Call   │
│  (AWS Amplify)   │
└────┬─────────────┘
     │ 4. mutation createTask { ... }
     │    Authorization: Bearer <JWT>
     │
     ▼
┌──────────────────┐
│    AppSync       │
│   (GraphQL)      │
└────┬─────────────┘
     │ 5. Validates JWT with Cognito
     │ 6. Routes to Lambda Data Source
     │
     ▼
┌──────────────────┐
│   Lambda         │
│ appsync-resolver │
└────┬─────────────┘
     │ 7. Validates input
     │ 8. Generates taskId (UUID)
     │ 9. Enriches data (timestamps, userId)
     │
     ▼
┌──────────────────┐
│   DynamoDB       │
│   PutItem        │
└────┬─────────────┘
     │ 10. Stores task record
     │ 11. Triggers DynamoDB Stream
     │
     ├────────────────────────────┐
     │                            │
     ▼                            ▼
┌──────────────────┐    ┌──────────────────┐
│  EventBridge     │    │  Lambda          │
│  PutEvents       │    │  stream-processor│
└────┬─────────────┘    └────┬─────────────┘
     │                       │
     │ 12. Publishes         │ 13. Indexes task
     │     "Task Created"    │     in OpenSearch
     │     event             │
     │                       ▼
     ▼                  ┌──────────────────┐
┌──────────────────┐   │   OpenSearch     │
│   Lambda         │   │   (Search)       │
│ notification-    │   └──────────────────┘
│ handler          │
└────┬─────────────┘
     │ 14. Fetches assignee details
     │ 15. Formats email content
     │
     ▼
┌──────────────────┐
│      SNS         │
│   (Email)        │
└────┬─────────────┘
     │ 16. Sends email notification
     │
     ▼
┌──────────────────┐
│  User's Inbox    │
│  "New task       │
│   assigned"      │
└──────────────────┘

Meanwhile...

┌──────────────────┐
│   CloudWatch     │
│    Logs          │
└──────────────────┘
     ▲
     │ All Lambdas write logs
     │ Retention: 30 days
     
┌──────────────────┐
│     X-Ray        │
│   (Tracing)      │
└──────────────────┘
     ▲
     │ Full request trace
     │ Performance metrics
```

**Timeline:**
- 0ms: User clicks "Create"
- 50ms: Frontend sends GraphQL request
- 100ms: AppSync validates and routes to Lambda
- 150ms: Lambda writes to DynamoDB
- 160ms: DynamoDB Stream triggers
- 200ms: EventBridge event published
- 250ms: Notification handler processes
- 300ms: Email sent
- **Total: ~300ms**

---

## Deployment Process

### Full Stack Deployment (Recommended)

**Using Deployment Script:**
```bash
# Deploy everything (infrastructure + Lambdas + frontend config)
./scripts/deploy.sh --environment sandbox

# What happens:
# 1. Pre-builds Lambda functions
# 2. Runs terraform apply (deploys infrastructure + Lambdas)
# 3. Extracts Terraform outputs
# 4. Creates frontend .env.production
# 5. Pushes config (Amplify auto-deploys on next commit)
```

**Manual Terraform Deployment:**
```bash
# 1. Build Lambda functions
./scripts/build-lambdas.sh

# 2. Deploy infrastructure
cd terraform
terraform init
terraform plan -var-file="environments/sandbox.tfvars" -out=tfplan
terraform apply tfplan

# 3. Extract outputs for frontend
terraform output -json > outputs.json

# 4. Configure frontend
cd ../frontend
cat > .env.production << EOF
NEXT_PUBLIC_API_URL=$(jq -r '.api_gateway_url.value' ../terraform/outputs.json)
NEXT_PUBLIC_APPSYNC_URL=$(jq -r '.appsync_graphql_url.value' ../terraform/outputs.json)
NEXT_PUBLIC_COGNITO_USER_POOL_ID=$(jq -r '.cognito_user_pool_id.value' ../terraform/outputs.json)
NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID=$(jq -r '.cognito_user_pool_client_id.value' ../terraform/outputs.json)
NEXT_PUBLIC_AWS_REGION=eu-west-1
EOF

# 5. Deploy frontend
amplify publish
# Or push to GitHub for auto-deploy
```

### CI/CD Deployment (GitHub Actions)

**Workflow: `.github/workflows/deploy.yml`**

```yaml
name: Full Stack Deployment

on:
  push:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      environment:
        required: true
        type: choice
        options: [sandbox, staging, production]

jobs:
  deploy-infrastructure:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: eu-west-1
      
      - name: Build Lambdas
        run: ./scripts/build-lambdas.sh
      
      - name: Deploy with Terraform
        working-directory: terraform
        run: |
          terraform init
          terraform plan -var-file="environments/${{ inputs.environment }}.tfvars" -out=tfplan
          terraform apply -auto-approve tfplan
  
  deploy-frontend:
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Extract Terraform Outputs
        run: ./scripts/deploy.sh --frontend-only
      
      - name: Deploy to Amplify
        # Amplify auto-deploys on commit to main/develop
        run: echo "Amplify will auto-deploy this commit"
```

**Deployment Triggers:**
- Push to `main` → Deploy to production
- Push to `develop` → Deploy to staging
- Manual workflow dispatch → Deploy to any environment

---

## Environment Configuration

### Terraform Variables

**File:** `terraform/environments/sandbox.tfvars`
```hcl
# Core settings
project_name = "task-manager"
environment  = "sandbox"
aws_region   = "eu-west-1"

# Cognito
allowed_email_domains = ["amalitech.com", "amalitechtraining.org"]
cognito_callback_urls = ["http://localhost:3000/auth/callback"]
cognito_logout_urls   = ["http://localhost:3000"]

# Lambda
lambda_runtime     = "nodejs18.x"
lambda_timeout     = 30
lambda_memory_size = 256

# API Gateway
api_throttle_rate_limit  = 1000  # requests per second
api_throttle_burst_limit = 2000

# Notifications
notification_emails = ["admin@amalitech.com"]

# Tags
tags = {
  Project     = "task-manager"
  Environment = "sandbox"
  ManagedBy   = "terraform"
}
```

**Production Overrides:** `terraform/environments/production.tfvars`
```hcl
environment = "production"

# Higher Lambda specs for production
lambda_timeout     = 60
lambda_memory_size = 512

# Stricter throttling
api_throttle_rate_limit  = 500
api_throttle_burst_limit = 1000

# Enable point-in-time recovery
enable_point_in_time_recovery = true

# Production callback URLs
cognito_callback_urls = ["https://taskmanager.amalitech.com/auth/callback"]
cognito_logout_urls   = ["https://taskmanager.amalitech.com"]
```

### Frontend Configuration

**Development:** `.env.local`
```bash
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_APPSYNC_URL=https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_COGNITO_USER_POOL_ID=eu-west-1_xxxxxx
NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxx
NEXT_PUBLIC_AWS_REGION=eu-west-1
```

**Production:** `.env.production` (generated by deployment script)
```bash
NEXT_PUBLIC_API_URL=https://api.taskmanager.amalitech.com
NEXT_PUBLIC_APPSYNC_URL=https://xxxxx.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_COGNITO_USER_POOL_ID=eu-west-1_xxxxxx
NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxx
NEXT_PUBLIC_AWS_REGION=eu-west-1
```

---

## Troubleshooting

### Common Issues

#### 1. Terraform Deployment Fails

**Symptom:** `terraform apply` fails with permission errors

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Ensure correct role/user has:
# - IAM: Full access
# - Lambda: Full access
# - DynamoDB: Full access
# - S3: Full access
# - API Gateway: Full access
# - Cognito: Full access
# - CloudWatch: Logs and metrics
```

#### 2. Lambda Function Not Updating

**Symptom:** Code changes not reflected after `terraform apply`

**Solution:**
```bash
# Force rebuild
rm lambda/*/function.zip

# Rebuild
./scripts/build-lambdas.sh

# Apply
cd terraform
terraform apply
```

#### 3. Frontend Can't Connect to API

**Symptom:** API calls return 403 or CORS errors

**Solution:**
```bash
# 1. Check environment variables
cd frontend
cat .env.production

# 2. Verify API Gateway CORS
aws apigateway get-rest-apis

# 3. Check Cognito token
# In browser console:
const session = await Auth.currentSession();
console.log(session.getIdToken().getJwtToken());

# 4. Verify token in jwt.io
# Should have:
# - "cognito:groups": ["Admins" or "Members"]
# - "email_verified": true
```

#### 4. Amplify Build Fails

**Symptom:** Amplify deployment fails during build

**Solution:**
```bash
# Check build logs in Amplify Console

# Common issues:
# 1. Missing environment variables
# 2. Node version mismatch
# 3. Dependency conflicts

# Fix:
# 1. Set all required env vars in Amplify Console
# 2. Update amplify.yml with correct Node version
# 3. Delete node_modules and package-lock.json, reinstall
```

#### 5. DynamoDB Access Denied

**Symptom:** Lambda can't read/write DynamoDB

**Solution:**
```bash
# Check Lambda IAM role
aws lambda get-function --function-name task-manager-sandbox-task-api \
  --query 'Configuration.Role'

# Check role permissions
aws iam get-role-policy --role-name <role-name> --policy-name <policy-name>

# Should include:
# - dynamodb:GetItem
# - dynamodb:PutItem
# - dynamodb:Query
# - dynamodb:UpdateItem
# - dynamodb:DeleteItem
```

### Debug Commands

```bash
# View Lambda logs
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow

# Test Lambda locally
aws lambda invoke \
  --function-name task-manager-sandbox-task-api \
  --payload '{"body":"{\"action\":\"list\"}"}' \
  response.json

# Check DynamoDB records
aws dynamodb scan --table-name task-manager-sandbox-tasks --limit 10

# View API Gateway logs
aws logs tail /aws/apigateway/task-manager-sandbox-api --follow

# Check Cognito user
aws cognito-idp admin-get-user \
  --user-pool-id <pool-id> \
  --username user@example.com
```

---

## Summary

This architecture provides:

✅ **Scalability:** Serverless auto-scales to demand  
✅ **Security:** Cognito auth, IAM roles, encryption at rest  
✅ **Observability:** CloudWatch logs, X-Ray tracing, alarms  
✅ **Maintainability:** Infrastructure as Code (Terraform)  
✅ **Developer Experience:** Automated builds, CI/CD  
✅ **Cost Efficiency:** Pay per use, no idle costs  

**Total Resources Managed:**
- 1 DynamoDB table with streams
- 1 Cognito User Pool with 2 groups
- 9 Lambda functions + 1 layer
- 2 APIs (REST + GraphQL)
- 1 S3 bucket
- 1 EventBridge bus
- 1 SNS topic
- 1 SES configuration
- 1 OpenSearch collection
- 40+ CloudWatch alarms
- 1 Amplify application

**All managed by Terraform in a single `terraform apply` command!**
