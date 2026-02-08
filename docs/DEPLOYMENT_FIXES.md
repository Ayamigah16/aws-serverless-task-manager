# Deployment Fixes & Troubleshooting

Critical fixes applied during deployment to resolve common issues.

---

## Issue 1: Lambda Functions Returning 502 Bad Gateway

**Symptom:**
```
GET /tasks 502 (Bad Gateway)
```

**Root Cause:** Lambda packages missing npm dependencies (AWS SDK, jsonwebtoken, jwks-rsa, uuid)

**Fix:** Updated `scripts/build-lambdas.sh` to install dependencies

```bash
# Added to build_lambda() function
if [[ -f package.json ]]; then
    npm install --production --silent
fi

# Package with node_modules
zip -qr function.zip index.js package.json node_modules/
```

**Commands:**
```bash
./scripts/build-lambdas.sh
cd terraform && terraform apply
```

---

## Issue 2: Lambda Functions Returning 500 Internal Server Error

**Symptom:**
```
GET /tasks 500 (Internal Server Error)
Token validation failed: error in secret or public key callback: Bad Request
```

**Root Cause:** Missing environment variables for JWT validation (USER_POOL_ID, AWS_REGION_NAME)

**Fix:** Added environment variables to task-api Lambda

**File:** `terraform/modules/lambda/main.tf`
```hcl
environment {
  variables = {
    TABLE_NAME      = var.dynamodb_table_name
    EVENT_BUS_NAME  = var.eventbridge_bus_name
    USER_POOL_ID    = var.cognito_user_pool_id  # Added
    AWS_REGION_NAME = var.aws_region             # Added
  }
}
```

**File:** `terraform/main.tf`
```hcl
module "lambda" {
  # ... other variables
  cognito_user_pool_id = module.cognito.user_pool_id  # Added
  aws_region           = var.aws_region                # Added
}
```

**Commands:**
```bash
cd terraform && terraform apply
```

---

## Issue 3: Frontend API Calls Returning 401 Unauthorized

**Symptom:**
```
GET /tasks 401 (Unauthorized)
```

**Root Cause:** Amplify not attaching JWT token to API requests

**Fix:** Added custom_header function to aws-config.js

**File:** `frontend/src/aws-config.js`
```javascript
import { Auth } from 'aws-amplify';

API: {
  endpoints: [{
    name: 'TaskAPI',
    endpoint: process.env.REACT_APP_API_URL,
    region: process.env.REACT_APP_REGION || 'eu-west-1',
    custom_header: async () => {
      try {
        const session = await Auth.currentSession();
        return {
          Authorization: `Bearer ${session.getIdToken().getJwtToken()}`
        };
      } catch (error) {
        console.error('Error getting auth token:', error);
        return {};
      }
    }
  }]
}
```

**Commands:**
```bash
cd frontend
npm start
```

---

## Issue 4: Cognito Sign-Up Error

**Symptom:**
```
Phone or email cannot be auto verified, when user is not being auto confirmed.
```

**Root Cause:** Pre Sign-Up trigger had `autoConfirmUser = false` but `autoVerifyEmail = true`

**Fix:** Changed autoConfirmUser to true

**File:** `lambda/pre-signup-trigger/index.js`
```javascript
event.response.autoConfirmUser = true;  // Changed from false
event.response.autoVerifyEmail = true;
```

**Commands:**
```bash
./scripts/build-lambdas.sh
aws lambda update-function-code \
  --function-name task-manager-sandbox-pre-signup \
  --zip-file fileb://lambda/pre-signup-trigger/function.zip \
  --region eu-west-1
```

---

## Issue 5: Terraform Not Detecting Lambda Code Changes

**Symptom:** Running `terraform apply` after code changes shows "No changes"

**Root Cause:** Terraform doesn't track zip file content by default

**Fix:** Added source_code_hash to all Lambda functions

**File:** `terraform/modules/lambda/main.tf`
```hcl
resource "aws_lambda_function" "task_api" {
  filename         = "path/to/function.zip"
  source_code_hash = filebase64sha256("path/to/function.zip")  # Added
  # ... other config
}
```

**Result:** Terraform now auto-detects code changes

---

## Issue 6: API Gateway CloudWatch Logging Error

**Symptom:**
```
CloudWatch Logs role ARN must be set in account settings to enable logging
```

**Root Cause:** API Gateway needs account-level IAM role for CloudWatch

**Fix:** Added IAM role and account settings

**File:** `terraform/modules/api-gateway/main.tf`
```hcl
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.api_name}-cloudwatch-role"
  # ... assume role policy
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_api_gateway_stage" "main" {
  # ... config
  depends_on = [aws_api_gateway_account.main]  # Added dependency
}
```

---

## Issue 7: Terraform State Corruption

**Symptom:**
```
Error: state data in S3 does not have the expected content.
Calculated checksum: xxx
Stored checksum: yyy
```

**Root Cause:** Interrupted `terraform apply` caused state mismatch

**Fix:** Update DynamoDB digest or delete lock item

**Commands:**
```bash
# Option 1: Update digest
aws dynamodb update-item \
  --table-name task-manager-terraform-locks \
  --key '{"LockID":{"S":"bucket/key-md5"}}' \
  --update-expression "SET Digest = :digest" \
  --expression-attribute-values '{":digest":{"S":"NEW_CHECKSUM"}}'

# Option 2: Delete lock (safer)
aws dynamodb delete-item \
  --table-name task-manager-terraform-locks \
  --key '{"LockID":{"S":"bucket/key-md5"}}'
```

---

## Issue 8: Lambda Function Already Exists

**Symptom:**
```
ResourceConflictException: Function already exist: task-manager-sandbox-task-api
```

**Root Cause:** Terraform state out of sync with AWS

**Fix:** Import existing resource

**Commands:**
```bash
terraform import module.lambda.aws_lambda_function.task_api task-manager-sandbox-task-api
terraform apply
```

---

## Complete Deployment Checklist

### 1. Build Lambda Packages
```bash
./scripts/build-lambdas.sh
```

### 2. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 3. Get Outputs
```bash
terraform output cognito_user_pool_id
terraform output cognito_user_pool_client_id
terraform output api_gateway_url
```

### 4. Update Frontend Config
Edit `frontend/.env`:
```env
REACT_APP_USER_POOL_ID=<from terraform output>
REACT_APP_USER_POOL_CLIENT_ID=<from terraform output>
REACT_APP_API_URL=<from terraform output>
```

### 5. Test Frontend
```bash
cd frontend
npm install
npm start
```

### 6. Create Test Users
```bash
aws cognito-idp admin-create-user \
  --user-pool-id <pool-id> \
  --username admin@amalitech.com \
  --user-attributes Name=email,Value=admin@amalitech.com Name=email_verified,Value=true

aws cognito-idp admin-add-user-to-group \
  --user-pool-id <pool-id> \
  --username admin@amalitech.com \
  --group-name Admins
```

---

## Verification Commands

### Check Lambda Logs
```bash
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow --region eu-west-1
```

### Check Lambda Configuration
```bash
aws lambda get-function-configuration \
  --function-name task-manager-sandbox-task-api \
  --region eu-west-1
```

### Test API Endpoint
```bash
curl -X GET "https://API_ID.execute-api.eu-west-1.amazonaws.com/sandbox/tasks" \
  -H "Authorization: Bearer JWT_TOKEN"
```

### Check Cognito Users
```bash
aws cognito-idp list-users \
  --user-pool-id <pool-id> \
  --region eu-west-1
```

---

## Common Issues & Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| 401 Unauthorized | Check JWT token in browser console |
| 403 Forbidden | Verify user in correct Cognito group |
| 500 Internal Error | Check Lambda logs |
| 502 Bad Gateway | Lambda missing dependencies or crashing |
| CORS Error | Redeploy API Gateway stage |
| Token expired | Refresh AWS credentials |
| Build fails | Run `npm install` in Lambda directories |

---

**Last Updated:** February 2026  
**Status:** All Issues Resolved ✅
