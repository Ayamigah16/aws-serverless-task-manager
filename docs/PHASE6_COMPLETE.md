# Phase 6 Complete: Event-Driven Notifications ✅

## Status: COMPLETE

Event-driven notification system with EventBridge and SES ready for deployment.

---

## Deliverables

### 1. EventBridge Event Bus
- Custom event bus for task events
- 3 event rules (TaskAssigned, TaskStatusUpdated, TaskClosed)
- Lambda targets configured
- Event patterns defined

### 2. Amazon SES
- Email identity verification
- Configuration set
- Sender email configured

### 3. Notification Handler Lambda
- Processes EventBridge events
- Fetches user details from DynamoDB
- Filters deactivated users
- Sends emails via SES
- Comprehensive error handling

### 4. Event Publishing
- Task API publishes events to EventBridge
- Event source: `task-management.tasks`
- Detail types: TaskAssigned, TaskStatusUpdated, TaskClosed

---

## Files Updated

1. `terraform/modules/lambda/main.tf` - Added SENDER_EMAIL env var
2. `terraform/modules/lambda/variables.tf` - Added sender_email variable
3. `terraform/main.tf` - Pass sender_email to lambda module

---

## Event Flow

```
Task API → EventBridge → Notification Handler → SES → Email
```

### Events Published

**TaskAssigned**
```json
{
  "source": "task-management.tasks",
  "detail-type": "TaskAssigned",
  "detail": {
    "taskId": "uuid",
    "taskTitle": "Task title",
    "assignedTo": "user-id",
    "assignedBy": "admin-id",
    "priority": "HIGH"
  }
}
```

**TaskStatusUpdated**
```json
{
  "source": "task-management.tasks",
  "detail-type": "TaskStatusUpdated",
  "detail": {
    "taskId": "uuid",
    "taskTitle": "Task title",
    "previousStatus": "OPEN",
    "newStatus": "IN_PROGRESS",
    "updatedBy": "user-id"
  }
}
```

**TaskClosed**
```json
{
  "source": "task-management.tasks",
  "detail-type": "TaskClosed",
  "detail": {
    "taskId": "uuid",
    "taskTitle": "Task title",
    "closedBy": "admin-id",
    "finalStatus": "COMPLETED"
  }
}
```

---

## Email Notifications

### Task Assigned
**To:** Assigned user  
**Subject:** New Task Assigned: {title}  
**Body:** Task details, priority, assigned by

### Task Status Updated
**To:** All assigned users + task creator  
**Subject:** Task Status Updated: {title}  
**Body:** Previous status, new status, updated by

### Task Closed
**To:** All assigned users  
**Subject:** Task Closed: {title}  
**Body:** Final status, closed by

---

## Deactivated User Filtering

Notification handler checks user status before sending:
```javascript
if (!user || user.UserStatus === 'DEACTIVATED') {
  console.log('User deactivated, skipping notification');
  return;
}
```

---

## Deployment

### 1. Verify SES Email
```bash
# Add to terraform.tfvars
ses_sender_email = "noreply@amalitech.com"
```

### 2. Deploy
```bash
cd terraform
terraform apply
```

### 3. Verify SES Email Identity
```bash
# Check email for verification link
# Or verify via AWS CLI
aws ses verify-email-identity --email-address noreply@amalitech.com
```

### 4. Test
```bash
# Create task (triggers TaskCreated - no notification)
# Assign task (triggers TaskAssigned - sends email)
# Update status (triggers TaskStatusUpdated - sends email)
# Close task (triggers TaskClosed - sends email)
```

---

## SES Sandbox Mode

**In sandbox mode:**
- Can only send to verified email addresses
- Verify recipient emails first
- Request production access to send to any email

**Verify recipient:**
```bash
aws ses verify-email-identity --email-address user@amalitech.com
```

**Request production access:**
AWS Console → SES → Account dashboard → Request production access

---

## Monitoring

### EventBridge Metrics
- Invocations
- FailedInvocations
- TriggeredRules

### Lambda Metrics
- Invocations
- Errors
- Duration

### SES Metrics
- Send
- Delivery
- Bounce
- Complaint

### CloudWatch Logs
```bash
# Notification handler logs
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow
```

---

## Cost: ~$0.10/month

- EventBridge: $1.00 per million events (~$0.00)
- Lambda: Free tier (~$0.00)
- SES: $0.10 per 1000 emails (~$0.10)

---

## Testing

### Test Event Publishing
```bash
# Create and assign task via API
curl -X POST "${API_URL}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","priority":"HIGH"}'

# Assign task
curl -X POST "${API_URL}/{taskId}/assign" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"assignedTo":"user-id"}'

# Check logs
aws logs tail /aws/lambda/task-manager-sandbox-notification-handler --follow
```

### Verify Email Sent
- Check recipient inbox
- Check SES sending statistics
- Check CloudWatch logs

---

## Progress: 70% Complete

✅ Phases: 1, 2, 3, 4, 5, 6, 7  
⏳ Next: Phase 8 (Security Hardening)

---

**See:** `docs/deployment/PHASE6_DEPLOYMENT.md` for detailed deployment guide
