# Enhanced Serverless Task Manager - Deployment Guide

## 🚀 Overview

This guide covers deploying the enhanced serverless task management system with:
- AppSync GraphQL API with real-time subscriptions
- OpenSearch Serverless for full-text search
- S3 file attachments with processing
- GitHub webhook integration
- DynamoDB Streams for event-driven updates

## 📋 Prerequisites

### Required Tools
- AWS CLI v2.x configured
- Terraform v1.5.0+
- Node.js v18.x+
- npm or yarn

### AWS Permissions
Ensure your IAM user/role has permissions for:
- AppSync
- OpenSearch Serverless
- S3
- Lambda
- DynamoDB Streams
- EventBridge
- IAM role creation

## 🔧 Phase 1: Update DynamoDB Table

### 1.1 Enable DynamoDB Streams

Update `terraform/modules/dynamodb/main.tf`:

```hcl
resource "aws_dynamodb_table" "main" {
  # ... existing configuration ...

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Add new GSIs
  global_secondary_index {
    name            = "GSI3"
    hash_key        = "GSI3PK"
    range_key       = "GSI3SK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "GSI4"
    hash_key        = "GSI4PK"
    range_key       = "GSI4SK"
    projection_type = "ALL"
  }
}

# Add attributes
attribute {
  name = "GSI3PK"
  type = "S"
}

attribute {
  name = "GSI3SK"
  type = "S"
}

attribute {
  name = "GSI4PK"
  type = "S"
}

attribute {
  name = "GSI4SK"
  type = "S"
}
```

### 1.2 Deploy DynamoDB Changes

```bash
cd terraform
terraform plan
terraform apply
```

## 🔧 Phase 2: Deploy Lambda Functions

### 2.1 Build New Lambda Functions

```bash
cd lambda

# AppSync Resolver
cd appsync-resolver
npm install
zip -r function.zip index.js node_modules/
cd ..

# Stream Processor
cd stream-processor
npm install
zip -r function.zip index.js node_modules/
cd ..

# File Processor
cd file-processor
npm install
zip -r function.zip index.js node_modules/
cd ..

# Presigned URL Generator
cd presigned-url
npm install
zip -r function.zip index.js node_modules/
cd ..

# GitHub Webhook
cd github-webhook
npm install
zip -r function.zip index.js node_modules/
cd ..
```

### 2.2 Update Lambda Module

Add to `terraform/modules/lambda/main.tf`:

```hcl
# AppSync Resolver Lambda
resource "aws_lambda_function" "appsync_resolver" {
  filename         = "${path.root}/../lambda/appsync-resolver/function.zip"
  function_name    = "${var.name_prefix}-appsync-resolver"
  role            = aws_iam_role.appsync_resolver.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

  environment {
    variables = {
      TABLE_NAME     = var.dynamodb_table_name
      EVENT_BUS_NAME = var.eventbridge_bus_name
    }
  }
}

# Stream Processor Lambda
resource "aws_lambda_function" "stream_processor" {
  filename         = "${path.root}/../lambda/stream-processor/function.zip"
  function_name    = "${var.name_prefix}-stream-processor"
  role            = aws_iam_role.stream_processor.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      OPENSEARCH_ENDPOINT = var.opensearch_endpoint
      AWS_REGION         = var.aws_region
    }
  }
}

# Event source mapping for DynamoDB Streams
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = var.dynamodb_stream_arn
  function_name     = aws_lambda_function.stream_processor.arn
  starting_position = "LATEST"
  batch_size        = 10
}

# File Processor Lambda
resource "aws_lambda_function" "file_processor" {
  filename         = "${path.root}/../lambda/file-processor/function.zip"
  function_name    = "${var.name_prefix}-file-processor"
  role            = aws_iam_role.file_processor.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = 60
  memory_size     = 1024

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table_name
    }
  }
}

# GitHub Webhook Lambda
resource "aws_lambda_function" "github_webhook" {
  filename         = "${path.root}/../lambda/github-webhook/function.zip"
  function_name    = "${var.name_prefix}-github-webhook"
  role            = aws_iam_role.github_webhook.arn
  handler         = "index.handler"
  runtime         = var.runtime
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      TABLE_NAME            = var.dynamodb_table_name
      EVENT_BUS_NAME        = var.eventbridge_bus_name
      GITHUB_WEBHOOK_SECRET = var.github_webhook_secret
    }
  }
}
```

## 🔧 Phase 3: Deploy AppSync

### 3.1 Update Main Terraform

Add to `terraform/main.tf`:

```hcl
# AppSync GraphQL API
module "appsync" {
  source = "./modules/appsync"

  api_name              = "${local.name_prefix}-graphql"
  aws_region            = var.aws_region
  cognito_user_pool_id  = module.cognito.user_pool_id
  dynamodb_table_name   = module.dynamodb.table_name
  dynamodb_table_arn    = module.dynamodb.table_arn
  resolver_lambda_arn   = module.lambda.appsync_resolver_lambda_arn
  opensearch_endpoint   = module.opensearch.collection_endpoint
  opensearch_arn        = module.opensearch.collection_arn
  project_name          = var.project_name
  environment           = var.environment
}
```

### 3.2 Deploy AppSync

```bash
cd terraform
terraform plan
terraform apply
```

### 3.3 Get AppSync Endpoints

```bash
terraform output appsync_graphql_endpoint
terraform output appsync_realtime_endpoint
terraform output appsync_api_key
```

## 🔧 Phase 4: Deploy OpenSearch

### 4.1 Add OpenSearch Module

Add to `terraform/main.tf`:

```hcl
module "opensearch" {
  source = "./modules/opensearch"

  collection_name   = "${local.name_prefix}-search"
  lambda_role_arn   = module.lambda.stream_processor_role_arn
  appsync_role_arn  = module.appsync.appsync_opensearch_role_arn
  project_name      = var.project_name
  environment       = var.environment
}
```

### 4.2 Deploy OpenSearch

```bash
cd terraform
terraform apply
```

**Note**: OpenSearch Serverless takes 10-15 minutes to provision.

### 4.3 Create Indexes

After deployment, create indexes:

```bash
# Get OpenSearch endpoint
OPENSEARCH_ENDPOINT=$(terraform output -raw opensearch_endpoint)

# Create tasks index
curl -X PUT "$OPENSEARCH_ENDPOINT/tasks" \
  -H "Content-Type: application/json" \
  --aws-sigv4 "aws:amz:us-east-1:aoss" \
  -d '{
    "mappings": {
      "properties": {
        "taskId": { "type": "keyword" },
        "title": { "type": "text" },
        "description": { "type": "text" },
        "status": { "type": "keyword" },
        "priority": { "type": "keyword" },
        "labels": { "type": "keyword" },
        "createdAt": { "type": "date" }
      }
    }
  }'

# Create comments index
curl -X PUT "$OPENSEARCH_ENDPOINT/comments" \
  -H "Content-Type: application/json" \
  --aws-sigv4 "aws:amz:us-east-1:aoss" \
  -d '{
    "mappings": {
      "properties": {
        "commentId": { "type": "keyword" },
        "taskId": { "type": "keyword" },
        "content": { "type": "text" },
        "createdAt": { "type": "date" }
      }
    }
  }'
```

## 🔧 Phase 5: Deploy S3 File Storage

### 5.1 Add S3 Module

Add to `terraform/main.tf`:

```hcl
module "s3" {
  source = "./modules/s3"

  bucket_name                 = "${local.name_prefix}-attachments"
  file_processor_lambda_arn   = module.lambda.file_processor_lambda_arn
  file_processor_lambda_name  = module.lambda.file_processor_lambda_name
  lambda_role_arn            = module.lambda.file_processor_role_arn
  allowed_origins            = var.cors_allowed_origins
  project_name               = var.project_name
  environment                = var.environment
}
```

### 5.2 Deploy S3

```bash
cd terraform
terraform apply
```

## 🔧 Phase 6: Configure GitHub Webhook

### 6.1 Store Webhook Secret

```bash
# Generate a secure secret
WEBHOOK_SECRET=$(openssl rand -hex 32)

# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name /task-manager/github-webhook-secret \
  --secret-string "$WEBHOOK_SECRET"
```

### 6.2 Get Webhook URL

```bash
# Get API Gateway URL
API_URL=$(cd terraform && terraform output -raw api_gateway_url)
WEBHOOK_URL="${API_URL}/webhooks/github"

echo "GitHub Webhook URL: $WEBHOOK_URL"
```

### 6.3 Configure GitHub Repository

1. Go to your GitHub repository
2. Navigate to Settings → Webhooks → Add webhook
3. Set Payload URL: `$WEBHOOK_URL`
4. Set Content type: `application/json`
5. Set Secret: Use the `$WEBHOOK_SECRET` from step 6.1
6. Select events:
   - Push events
   - Pull requests
   - Pull request reviews
7. Click "Add webhook"

## 🔧 Phase 7: Update Frontend

### 7.1 Install AppSync Client

```bash
cd frontend
npm install @aws-amplify/api-graphql aws-amplify
```

### 7.2 Update AWS Config

Update `frontend/src/aws-config.js`:

```javascript
export const awsConfig = {
  // Existing config...
  
  // AppSync Configuration
  aws_appsync_graphqlEndpoint: 'YOUR_APPSYNC_ENDPOINT',
  aws_appsync_region: 'us-east-1',
  aws_appsync_authenticationType: 'AMAZON_COGNITO_USER_POOLS',
  aws_appsync_apiKey: 'YOUR_API_KEY', // Optional, for public access
};
```

### 7.3 Create GraphQL Client

Create `frontend/src/services/graphqlClient.js`:

```javascript
import { Amplify } from 'aws-amplify';
import { generateClient } from 'aws-amplify/api';
import { awsConfig } from '../aws-config';

Amplify.configure(awsConfig);

export const client = generateClient();
```

### 7.4 Add Real-time Subscriptions

Create `frontend/src/hooks/useTaskSubscription.js`:

```javascript
import { useEffect, useState } from 'react';
import { client } from '../services/graphqlClient';

const onTaskUpdated = `
  subscription OnTaskUpdated($taskId: ID!) {
    onTaskUpdated(taskId: $taskId) {
      taskId
      title
      status
      priority
      updatedAt
    }
  }
`;

export function useTaskSubscription(taskId) {
  const [task, setTask] = useState(null);

  useEffect(() => {
    const subscription = client.graphql({
      query: onTaskUpdated,
      variables: { taskId }
    }).subscribe({
      next: ({ data }) => {
        setTask(data.onTaskUpdated);
      },
      error: (error) => console.error('Subscription error:', error)
    });

    return () => subscription.unsubscribe();
  }, [taskId]);

  return task;
}
```

## 🔧 Phase 8: Testing

### 8.1 Test AppSync API

```bash
# Test GraphQL query
curl -X POST \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"query": "{ listTasks { items { taskId title status } } }"}' \
  YOUR_APPSYNC_ENDPOINT
```

### 8.2 Test File Upload

```javascript
// Get presigned URL
const { data } = await client.graphql({
  query: getPresignedUploadUrl,
  variables: {
    fileName: 'test.jpg',
    fileType: 'image/jpeg',
    taskId: 'task-123'
  }
});

// Upload file
await fetch(data.getPresignedUploadUrl.url, {
  method: 'PUT',
  body: file,
  headers: {
    'Content-Type': 'image/jpeg'
  }
});
```

### 8.3 Test GitHub Webhook

```bash
# Create a test commit with task reference
git commit -m "TASK-123: Fix bug [completed]"
git push

# Check task was updated
aws dynamodb get-item \
  --table-name task-manager-sandbox-tasks \
  --key '{"PK": {"S": "TASK#123"}, "SK": {"S": "METADATA"}}'
```

### 8.4 Test Search

```bash
# Search for tasks
curl -X POST \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"query": "{ searchTasks(input: {query: \"bug fix\"}) { tasks { taskId title } total } }"}' \
  YOUR_APPSYNC_ENDPOINT
```

## 📊 Monitoring

### View CloudWatch Logs

```bash
# AppSync logs
aws logs tail /aws/appsync/task-manager-sandbox-graphql --follow

# Lambda logs
aws logs tail /aws/lambda/task-manager-sandbox-appsync-resolver --follow
aws logs tail /aws/lambda/task-manager-sandbox-stream-processor --follow
aws logs tail /aws/lambda/task-manager-sandbox-file-processor --follow
```

### View OpenSearch Dashboard

```bash
# Get dashboard URL
cd terraform
terraform output opensearch_dashboard_endpoint
```

## 🔒 Security Checklist

- [ ] AppSync API uses Cognito authentication
- [ ] S3 bucket has public access blocked
- [ ] GitHub webhook secret is stored securely
- [ ] Lambda functions have least-privilege IAM roles
- [ ] OpenSearch has proper access policies
- [ ] All data encrypted at rest and in transit
- [ ] CloudWatch logging enabled for all services

## 💰 Cost Monitoring

### Estimated Monthly Costs

- **AppSync**: $4 per million requests + $2 per million minutes
- **OpenSearch Serverless**: ~$100 (4 OCU minimum)
- **S3**: $0.023 per GB + $0.005 per 1000 requests
- **Lambda**: $0.20 per 1M requests + compute time
- **DynamoDB Streams**: $0.02 per 100K read requests

### Set Up Cost Alerts

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name task-manager-monthly-cost \
  --alarm-description "Alert when monthly cost exceeds $200" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --evaluation-periods 1 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold
```

## 🐛 Troubleshooting

### AppSync Returns 401 Unauthorized
- Verify Cognito token is valid
- Check user is in correct Cognito group
- Verify AppSync authentication configuration

### OpenSearch Connection Fails
- Verify collection is in ACTIVE state
- Check IAM permissions for Lambda role
- Verify network access policy allows Lambda

### File Upload Fails
- Check S3 bucket CORS configuration
- Verify presigned URL hasn't expired
- Check file size and type restrictions

### GitHub Webhook Not Working
- Verify webhook secret matches
- Check Lambda logs for errors
- Verify API Gateway endpoint is accessible

## 📚 Next Steps

1. **Add More Integrations**: Slack, Teams, JIRA
2. **Implement Analytics**: QuickSight dashboards
3. **Add Caching**: ElastiCache Redis
4. **Set Up CI/CD**: CodePipeline for automated deployments
5. **Add WAF**: Protect API Gateway with AWS WAF
6. **Implement Step Functions**: Complex workflow automation

## 🎉 Success!

Your enhanced serverless task manager is now deployed with:
- ✅ Real-time GraphQL API
- ✅ Full-text search
- ✅ File attachments
- ✅ GitHub integration
- ✅ Event-driven architecture

---

**Need Help?** Check the troubleshooting section or review CloudWatch logs for detailed error messages.
