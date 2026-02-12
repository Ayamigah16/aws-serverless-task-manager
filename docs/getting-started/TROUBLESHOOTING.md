# Troubleshooting Guide

## Common Issues

### Authentication Issues

**Cannot sign up with email**
- **Cause:** Email domain not allowed
- **Solution:** Use @amalitech.com or @amalitechtraining.org email
- **Check:** `aws logs tail /aws/lambda/task-manager-sandbox-pre-signup`

**Email verification code not received**
- **Cause:** SES in sandbox mode or email not verified
- **Solution:** Check spam folder, verify SES email identity
- **Check:** `aws ses get-identity-verification-attributes --identities <email>`

**Cannot sign in after verification**
- **Cause:** User not confirmed in Cognito
- **Solution:** Manually confirm user
- **Fix:** `aws cognito-idp admin-confirm-sign-up --user-pool-id <id> --username <email>`

---

### API Issues

**401 Unauthorized**
- **Cause:** Invalid or expired JWT token
- **Solution:** Sign out and sign in again
- **Check:** Token expiration (1 hour for access token)

**403 Forbidden**
- **Cause:** Insufficient permissions (RBAC)
- **Solution:** Verify user has correct role (Admin/Member)
- **Check:** User group membership in Cognito

**429 Too Many Requests**
- **Cause:** Rate limiting triggered
- **Solution:** Wait and retry, reduce request frequency
- **Check:** API Gateway throttling settings (1000 req/s)

**500 Internal Server Error**
- **Cause:** Lambda function error
- **Solution:** Check CloudWatch logs
- **Check:** `aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow`

---

### Task Management Issues

**Cannot create task**
- **Cause:** Not an admin user
- **Solution:** Verify user is in Admins group
- **Check:** `aws cognito-idp admin-list-groups-for-user --user-pool-id <id> --username <email>`

**Task assignment fails**
- **Cause:** User deactivated or already assigned
- **Solution:** Check user status, verify not duplicate
- **Check:** DynamoDB for existing assignment

**Email notification not sent**
- **Cause:** SES sandbox mode, user deactivated, or SES error
- **Solution:** Verify SES email, check user status
- **Check:** `aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow`

---

### Infrastructure Issues

**Terraform apply fails**
- **Cause:** Missing Lambda zip files, invalid configuration
- **Solution:** Build Lambda functions first
- **Fix:** `cd scripts && ./build-lambdas.sh`

**Lambda function not found**
- **Cause:** Function not deployed or wrong name
- **Solution:** Verify Terraform applied successfully
- **Check:** `aws lambda list-functions --query 'Functions[?contains(FunctionName, \`task-manager\`)].FunctionName'`

**DynamoDB throttling**
- **Cause:** Exceeded on-demand capacity
- **Solution:** Wait for auto-scaling, check query patterns
- **Check:** CloudWatch metrics for UserErrors

---

### Frontend Issues

**CORS error**
- **Cause:** API Gateway CORS not configured
- **Solution:** Redeploy API Gateway
- **Fix:** `cd terraform && terraform apply -replace="module.api_gateway.aws_api_gateway_deployment.main"`

**Cannot connect to API**
- **Cause:** Wrong API URL in .env
- **Solution:** Update REACT_APP_API_URL
- **Check:** `terraform output api_gateway_url`

**Infinite redirect loop**
- **Cause:** Cognito callback URL mismatch
- **Solution:** Update callback URLs in terraform.tfvars
- **Check:** Cognito User Pool Client settings

---

## Diagnostic Commands

### Check Cognito
```bash
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id)
aws cognito-idp describe-user-pool --user-pool-id $USER_POOL_ID
aws cognito-idp list-users --user-pool-id $USER_POOL_ID
```

### Check API Gateway
```bash
aws apigateway get-rest-apis --query 'items[?name==`task-manager-sandbox-api`]'
```

### Check Lambda
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `task-manager`)].FunctionName'
aws lambda get-function --function-name task-manager-sandbox-task-api
```

### Check DynamoDB
```bash
TABLE_NAME=$(terraform output -raw dynamodb_table_name)
aws dynamodb describe-table --table-name $TABLE_NAME
```

### Check Logs
```bash
# API Gateway
aws logs tail /aws/apigateway/task-manager-sandbox-api --follow

# Lambda
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow

# Filter errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/task-manager-sandbox-task-api \
  --filter-pattern "ERROR"
```

### Check Alarms
```bash
aws cloudwatch describe-alarms --alarm-name-prefix task-manager-sandbox
```

---

## Getting Help

1. Check CloudWatch logs first
2. Review error messages carefully
3. Verify configuration in terraform.tfvars
4. Test with curl/Postman to isolate issue
5. Check AWS service health dashboard
6. Contact support with logs and error details

---

## Emergency Procedures

### Rollback Deployment
```bash
cd terraform
terraform destroy -target=module.api_gateway
terraform apply
```

### Reset User Password
```bash
aws cognito-idp admin-set-user-password \
  --user-pool-id <id> \
  --username <email> \
  --password <new-password> \
  --permanent
```

### Clear DynamoDB Table
```bash
# Backup first!
aws dynamodb scan --table-name <table> > backup.json

# Delete items (use with caution)
```

### Disable Alarms Temporarily
```bash
aws cloudwatch disable-alarm-actions \
  --alarm-names task-manager-sandbox-api-5xx-errors
```
