# Implementation Guide

Complete guide for implementing the AWS Serverless Task Management System.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [Frontend Deployment](#frontend-deployment)
5. [Testing & Validation](#testing--validation)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
```bash
# Check versions
aws --version        # >= 2.x
terraform --version  # >= 1.5.0
node --version       # >= 18.x
npm --version        # >= 9.x
```

### AWS Account
- Active AWS account with appropriate permissions
- AWS CLI configured with credentials
- Region: `eu-west-1` (Ireland)

---

## Initial Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd aws-serverless-task-manager
```

### 2. Configure AWS CLI
```bash
aws configure
# Enter: Access Key, Secret Key, Region (eu-west-1), Output (json)
```

### 3. Set Up Remote State
```bash
./scripts/setup-remote-state.sh
```

This creates:
- S3 bucket: `task-manager-terraform-state-eu-west-1`
- DynamoDB table: `task-manager-terraform-locks`

---

## Infrastructure Deployment

### 1. Build Lambda Packages
```bash
./scripts/build-lambdas.sh
```

Creates deployment packages:
- `lambda/pre-signup-trigger/function.zip`
- `lambda/task-api/function.zip`
- `lambda/notification-handler/function.zip`

### 2. Configure Terraform Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_name = "task-manager"
environment  = "sandbox"
aws_region   = "eu-west-1"
ses_sender_email = "your-email@amalitech.com"
```

### 3. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### 4. Save Outputs
```bash
# Get Cognito details
terraform output cognito_user_pool_id
terraform output cognito_user_pool_client_id
terraform output api_gateway_url

# Save these for frontend configuration
```

### 5. Verify SES Email
```bash
# Check AWS Console > SES > Email Identities
# Click verification link in email
```

---

## Frontend Deployment

### 1. Update Configuration
Edit `frontend/src/aws-config.js`:
```javascript
export const awsConfig = {
  region: 'eu-west-1',
  userPoolId: 'eu-west-1_HyoUb4gyz',  // From terraform output
  userPoolWebClientId: 'YOUR_CLIENT_ID',  // From terraform output
  apiEndpoint: 'https://YOUR_API_ID.execute-api.eu-west-1.amazonaws.com/sandbox'
};
```

### 2. Test Locally
```bash
cd frontend
npm install
npm start
```

Visit `http://localhost:3000`

### 3. Deploy to Amplify

#### Option A: AWS Console
1. Go to AWS Amplify Console
2. Click "New app" > "Host web app"
3. Connect repository
4. Configure build settings
5. Deploy

#### Option B: Amplify CLI
```bash
npm install -g @aws-amplify/cli
amplify init
amplify add hosting
amplify publish
```

---

## Testing & Validation

### 1. Create Test Users
```bash
# Create admin user
aws cognito-idp admin-create-user \
  --user-pool-id eu-west-1_HyoUb4gyz \
  --username admin@amalitech.com \
  --user-attributes Name=email,Value=admin@amalitech.com Name=email_verified,Value=true

# Add to Admins group
aws cognito-idp admin-add-user-to-group \
  --user-pool-id eu-west-1_HyoUb4gyz \
  --username admin@amalitech.com \
  --group-name Admins

# Create member user
aws cognito-idp admin-create-user \
  --user-pool-id eu-west-1_HyoUb4gyz \
  --username member@amalitech.com \
  --user-attributes Name=email,Value=member@amalitech.com Name=email_verified,Value=true

# Add to Members group
aws cognito-idp admin-add-user-to-group \
  --user-pool-id eu-west-1_HyoUb4gyz \
  --username member@amalitech.com \
  --group-name Members
```

### 2. Test Authentication
1. Open frontend URL
2. Sign in with admin user
3. Complete password setup
4. Verify dashboard loads

### 3. Test Admin Flow
1. Create a new task
2. Assign task to member
3. Verify task appears in list
4. Check email notification sent

### 4. Test Member Flow
1. Sign out and sign in as member
2. Verify only assigned tasks visible
3. Update task status
4. Verify notification sent
5. Try to create task (should fail)

### 5. Test Notifications
```bash
# Check CloudWatch Logs
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow

# Check SES sending statistics
aws ses get-send-statistics --region eu-west-1
```

---

## Troubleshooting

### Issue: "Email domain not allowed"
**Solution:** Ensure email ends with `@amalitech.com` or `@amalitechtraining.org`

### Issue: "User not confirmed"
**Solution:** 
```bash
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id eu-west-1_HyoUb4gyz \
  --username user@amalitech.com
```

### Issue: "403 Forbidden" on API calls
**Solution:** 
- Check user is in correct Cognito group
- Verify JWT token is being sent
- Check CloudWatch logs for Lambda errors

### Issue: Emails not sending
**Solution:**
- Verify SES email identity
- Check SES is out of sandbox mode
- Check CloudWatch logs for SES errors

### Issue: Lambda errors
**Solution:**
```bash
# View logs
aws logs tail /aws/lambda/FUNCTION_NAME --follow

# Check function configuration
aws lambda get-function --function-name FUNCTION_NAME
```

### Issue: Terraform state locked
**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

---

## Useful Commands

### Terraform
```bash
# View state
terraform show

# List resources
terraform state list

# Destroy everything
terraform destroy
```

### Lambda
```bash
# Update function code
aws lambda update-function-code \
  --function-name FUNCTION_NAME \
  --zip-file fileb://function.zip

# Invoke function
aws lambda invoke \
  --function-name FUNCTION_NAME \
  --payload '{}' \
  response.json
```

### DynamoDB
```bash
# Scan table
aws dynamodb scan \
  --table-name task-manager-sandbox-tasks \
  --max-items 10

# Get item
aws dynamodb get-item \
  --table-name task-manager-sandbox-tasks \
  --key '{"PK":{"S":"TASK#123"},"SK":{"S":"METADATA"}}'
```

### CloudWatch
```bash
# View logs
aws logs tail /aws/lambda/FUNCTION_NAME --follow

# Get log groups
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/task-manager
```

---

## Next Steps

After successful deployment:
1. ✅ Test all user flows
2. ✅ Verify notifications working
3. ✅ Check CloudWatch metrics
4. ✅ Review security settings
5. ✅ Document any issues
6. ✅ Set up monitoring alerts

---

For detailed phase-specific information, see:
- [Architecture Documentation](architecture/)
- [Deployment Guides](deployment/)
- [Project Status](PROJECT_STATUS.md)
