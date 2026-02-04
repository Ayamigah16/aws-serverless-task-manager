# Phase 6 Deployment Guide

## Prerequisites
- Phase 3, 4, 5 deployed
- Valid email address for SES sender

---

## Deploy

### 1. Configure SES Sender Email
```bash
cd terraform
nano terraform.tfvars
```

Set:
```hcl
ses_sender_email = "noreply@amalitech.com"
```

### 2. Deploy Infrastructure
```bash
terraform apply
```

### 3. Verify SES Email Identity
Check email inbox for verification link from AWS SES, or:

```bash
aws ses verify-email-identity --email-address noreply@amalitech.com
```

### 4. Verify Email Status
```bash
aws ses get-identity-verification-attributes \
  --identities noreply@amalitech.com
```

Expected: `VerificationStatus: Success`

---

## Test Notifications

### 1. Verify Recipient Email (Sandbox Mode)
```bash
aws ses verify-email-identity --email-address user@amalitech.com
```

### 2. Create and Assign Task
```bash
API_URL=$(terraform output -raw api_gateway_url)
JWT_TOKEN="your-admin-token"

# Create task
TASK_ID=$(curl -X POST "${API_URL}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Notification","priority":"HIGH"}' \
  | jq -r '.taskId')

# Assign task (triggers email)
curl -X POST "${API_URL}/${TASK_ID}/assign" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"assignedTo":"user-id"}'
```

### 3. Check Logs
```bash
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow
```

### 4. Verify Email Received
Check recipient inbox for "New Task Assigned" email.

---

## Move SES Out of Sandbox

### Request Production Access
1. Go to AWS Console → SES
2. Click "Account dashboard"
3. Click "Request production access"
4. Fill out form:
   - Use case: Task management notifications
   - Website URL: Your app URL
   - Describe use case
   - Compliance: Yes
5. Submit request

**Approval time:** 24-48 hours

---

## Troubleshooting

### Email Not Received

**Check 1: SES Email Verified**
```bash
aws ses get-identity-verification-attributes \
  --identities noreply@amalitech.com
```

**Check 2: Recipient Verified (Sandbox)**
```bash
aws ses get-identity-verification-attributes \
  --identities user@amalitech.com
```

**Check 3: Lambda Logs**
```bash
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow
```

**Check 4: EventBridge Invocations**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=task-manager-sandbox-events-task-assigned \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### SES Bounce/Complaint

**Check bounce rate:**
```bash
aws ses get-send-statistics
```

**Set up bounce handling:**
- Configure SNS topic for bounces
- Update SES configuration set

---

## Monitoring

### View SES Statistics
```bash
aws ses get-send-statistics
```

### View EventBridge Metrics
```bash
# Failed invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name FailedInvocations \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### View Lambda Errors
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=task-manager-sandbox-notification-handler \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

---

## Success Criteria

- [ ] SES sender email verified
- [ ] EventBridge rules created
- [ ] Lambda permissions configured
- [ ] Task assignment sends email
- [ ] Status update sends email
- [ ] Task close sends email
- [ ] Deactivated users filtered
- [ ] CloudWatch logs show events

---

**Time:** ~10 minutes  
**Cost:** ~$0.10/month
