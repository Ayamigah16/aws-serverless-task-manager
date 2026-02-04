# Phase 5 Deployment Guide

## Prerequisites
- Phase 3 deployed (Cognito)
- Phase 4 deployed (DynamoDB)
- Lambda functions built

---

## Deploy

### 1. Verify Lambda Layer
```bash
ls -lh lambda/layers/shared-layer.zip
```

If missing:
```bash
cd lambda/layers/shared-layer
zip -r ../shared-layer.zip nodejs/
```

### 2. Rebuild Task API
```bash
cd lambda/task-api
zip -r function.zip index.js package.json
```

### 3. Deploy
```bash
cd terraform
terraform apply
```

### 4. Get API URL
```bash
terraform output api_gateway_url
```

---

## Test

### Get JWT Token

**Option 1: Cognito Hosted UI**
```bash
COGNITO_DOMAIN=$(terraform output -raw cognito_domain)
CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id)
REGION=$(terraform output -raw region)

echo "https://${COGNITO_DOMAIN}.auth.${REGION}.amazoncognito.com/login?client_id=${CLIENT_ID}&response_type=code&redirect_uri=http://localhost:3000"
```

Sign in and get token from browser console.

**Option 2: AWS CLI**
```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id $(terraform output -raw cognito_user_pool_client_id) \
  --auth-parameters USERNAME=admin@amalitech.com,PASSWORD=YourPassword123!
```

### Test Endpoints

```bash
API_URL=$(terraform output -raw api_gateway_url)
JWT_TOKEN="your-jwt-token"

# List tasks
curl -X GET "${API_URL}" -H "Authorization: Bearer ${JWT_TOKEN}"

# Create task (admin)
curl -X POST "${API_URL}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","priority":"HIGH"}'

# Update status
TASK_ID="task-id"
curl -X PUT "${API_URL}/${TASK_ID}/status" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status":"IN_PROGRESS"}'
```

---

## Verify

```bash
# Check API
aws apigateway get-rest-apis --query 'items[?name==`task-manager-sandbox-api`]'

# Check Lambda
aws lambda list-functions --query 'Functions[?contains(FunctionName, `task-manager-sandbox`)].FunctionName'

# Check Layer
aws lambda list-layers --query 'Layers[?contains(LayerName, `shared-layer`)]'

# View logs
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow
```

---

## Troubleshooting

### 401 Unauthorized
- Verify token not expired
- Check Authorization header: `Bearer {token}`

### 403 Forbidden
- Check user group membership
- Verify admin for admin actions

### CORS Error
```bash
# Redeploy API
cd terraform
terraform apply -replace="module.api_gateway.aws_api_gateway_deployment.main"
```

### 500 Error
```bash
# Check Lambda logs
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow
```

---

## Frontend Integration

```bash
cd frontend
nano .env
```

Add:
```env
REACT_APP_API_URL=<from terraform output>
```

---

## Success Criteria

- [ ] API Gateway exists
- [ ] All 8 endpoints respond
- [ ] CORS works
- [ ] Admin can create tasks
- [ ] Member cannot create tasks
- [ ] CloudWatch logs visible

---

**Time:** ~10 minutes  
**Cost:** ~$1/month
