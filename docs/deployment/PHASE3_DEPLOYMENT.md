# Phase 3 Deployment Guide

## 🚀 Quick Deployment

### Prerequisites
- AWS CLI configured
- Terraform installed (v1.5.0+)
- Lambda functions built (function.zip files exist)

### Step 1: Verify Lambda Packages
```bash
ls -lh lambda/*/function.zip
```

Expected output:
```
lambda/notification-handler/function.zip
lambda/pre-signup-trigger/function.zip
lambda/task-api/function.zip
```

### Step 2: Configure Variables
```bash
cd terraform
nano terraform.tfvars
```

Update these values:
```hcl
admin_email      = "your-admin@amalitech.com"
ses_sender_email = "noreply@amalitech.com"
```

### Step 3: Initialize Terraform
```bash
terraform init
```

### Step 4: Review Plan
```bash
terraform plan
```

Expected resources:
- Cognito User Pool
- Cognito User Pool Client
- Cognito Domain
- Cognito Groups (Admins, Members)
- Lambda Functions (3)
- IAM Roles and Policies
- CloudWatch Log Groups
- DynamoDB Table
- EventBridge Event Bus
- API Gateway (if Phase 5 ready)

### Step 5: Deploy
```bash
terraform apply
```

Type `yes` when prompted.

### Step 6: Capture Outputs
```bash
terraform output
```

Save these values:
```bash
# For frontend .env file
terraform output cognito_user_pool_id
terraform output cognito_user_pool_client_id
terraform output cognito_domain
terraform output api_gateway_url
terraform output region
```

### Step 7: Update Frontend Config
```bash
cd ../frontend
cp .env.example .env
nano .env
```

Add Terraform outputs:
```env
REACT_APP_USER_POOL_ID=<cognito_user_pool_id>
REACT_APP_USER_POOL_CLIENT_ID=<cognito_user_pool_client_id>
REACT_APP_COGNITO_DOMAIN=<cognito_domain>
REACT_APP_API_URL=<api_gateway_url>
```

---

## 🧪 Testing Authentication

### Test 1: Access Hosted UI
```bash
# Get the Hosted UI URL
COGNITO_DOMAIN=$(terraform output -raw cognito_domain)
REGION=$(terraform output -raw region)
echo "https://${COGNITO_DOMAIN}.auth.${REGION}.amazoncognito.com/login?client_id=$(terraform output -raw cognito_user_pool_client_id)&response_type=code&redirect_uri=http://localhost:3000"
```

### Test 2: Sign Up with Valid Domain
1. Open Hosted UI URL
2. Click "Sign up"
3. Enter email: `test@amalitech.com`
4. Enter password (must meet policy)
5. Submit form
6. Check email for verification code
7. Enter verification code

### Test 3: Sign Up with Invalid Domain
1. Try email: `test@gmail.com`
2. Should fail with error message
3. Check CloudWatch logs:
```bash
aws logs tail /aws/lambda/task-manager-sandbox-pre-signup --follow
```

### Test 4: Sign In
1. After email verification, sign in
2. Should redirect to callback URL with authorization code
3. Frontend will exchange code for tokens

### Test 5: Verify JWT Token
```bash
# In browser console after sign-in
localStorage.getItem('CognitoIdentityServiceProvider.<client-id>.LastAuthUser')
```

---

## 🔍 Verification Commands

### Check User Pool
```bash
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID
```

### List Users
```bash
aws cognito-idp list-users --user-pool-id $USER_POOL_ID
```

### Check User Groups
```bash
aws cognito-idp list-groups --user-pool-id $USER_POOL_ID
```

### Add User to Admin Group
```bash
aws cognito-idp admin-add-user-to-group \
  --user-pool-id $USER_POOL_ID \
  --username "admin@amalitech.com" \
  --group-name "Admins"
```

### Check Lambda Function
```bash
aws lambda get-function --function-name task-manager-sandbox-pre-signup
```

### View Lambda Logs
```bash
aws logs tail /aws/lambda/task-manager-sandbox-pre-signup --follow
```

---

## 🛠️ Troubleshooting

### Issue: Terraform fails with "function.zip not found"
```bash
cd scripts
./build-lambdas.sh
cd ../terraform
terraform apply
```

### Issue: Cannot access Hosted UI
Check domain configuration:
```bash
aws cognito-idp describe-user-pool-domain \
  --domain task-manager-sandbox
```

### Issue: Email verification not received
1. Check SES sandbox mode
2. Verify email address in SES
3. Check Cognito email configuration

### Issue: Pre Sign-Up Lambda not triggered
Check Lambda permissions:
```bash
aws lambda get-policy \
  --function-name task-manager-sandbox-pre-signup
```

---

## 🧹 Cleanup (Optional)

To destroy all resources:
```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

---

## ✅ Success Criteria

Phase 3 is successfully deployed when:
- [ ] Cognito User Pool exists
- [ ] Hosted UI is accessible
- [ ] Sign-up with @amalitech.com succeeds
- [ ] Sign-up with @gmail.com fails
- [ ] Email verification works
- [ ] Sign-in after verification succeeds
- [ ] JWT token contains user email and groups
- [ ] CloudWatch logs show Lambda executions
- [ ] Admin and Member groups exist

---

## 📚 Next Steps

After successful deployment:
1. Create test users (1 admin, 2 members)
2. Verify RBAC groups
3. Test frontend authentication
4. Continue to Phase 5 (API Gateway)

---

**Deployment Time**: ~5-10 minutes  
**Cost**: ~$0.50/month  
**Status**: Ready for Production Testing
