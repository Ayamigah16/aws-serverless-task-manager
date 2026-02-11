# SNS Migration Summary

## Overview
Migrated from Amazon SES to Amazon SNS for notifications to avoid email verification requirements in AWS sandbox accounts.

## Files Created

### Terraform Modules
- `terraform/modules/sns/main.tf` - SNS topic and email subscriptions
- `terraform/modules/sns/variables.tf` - Module variables
- `terraform/modules/sns/outputs.tf` - Module outputs
- `terraform/outputs.tf` - Main Terraform outputs for SNS

### Lambda Functions
- `lambda/notification-handler/index.js` - Rewritten to use SNS
- `lambda/notification-handler/function.zip` - Deployment package (30MB)

### Scripts
- `scripts/deploy-sns.sh` - Automated deployment script
- `scripts/sns-setup-guide.sh` - Setup instructions

### Documentation
- `docs/SNS_MIGRATION.md` - Detailed migration guide

## Files Modified

### Terraform Configuration
- `terraform/main.tf` - Replaced SES module with SNS module
- `terraform/variables.tf` - Changed `ses_sender_email` to `notification_emails` list
- `terraform/terraform.tfvars` - Updated to use `notification_emails`
- `terraform/modules/lambda/main.tf` - Updated IAM policy and environment variables
- `terraform/modules/lambda/variables.tf` - Changed to use `sns_topic_arn`

## Key Changes

### 1. Notification Delivery
**Before (SES):**
- Individual emails to specific users
- Required email verification in sandbox
- User-specific content

**After (SNS):**
- Broadcast to all subscribers
- No verification required
- Message includes user context

### 2. IAM Permissions
**Before:**
```json
{
  "Action": ["ses:SendEmail", "ses:SendRawEmail"],
  "Resource": "*"
}
```

**After:**
```json
{
  "Action": "sns:Publish",
  "Resource": "<sns_topic_arn>"
}
```

### 3. Lambda Environment Variables
**Before:**
- `SENDER_EMAIL` - SES sender address

**After:**
- `SNS_TOPIC_ARN` - SNS topic ARN

### 4. Notification Function
**Before:**
```javascript
await sesClient.send(new SendEmailCommand({
  Source: SENDER_EMAIL,
  Destination: { ToAddresses: [userEmail] },
  Message: { Subject: {...}, Body: {...} }
}));
```

**After:**
```javascript
await snsClient.send(new PublishCommand({
  TopicArn: SNS_TOPIC_ARN,
  Subject: subject,
  Message: `${message}\n\nUser: ${userEmail}`
}));
```

## Deployment Steps

1. **Update Configuration:**
   ```bash
   # Edit terraform/terraform.tfvars
   notification_emails = ["admin@amalitech.com"]
   ```

2. **Deploy Infrastructure:**
   ```bash
   cd terraform
   terraform apply
   ```

3. **Deploy Lambda:**
   ```bash
   cd ../lambda/notification-handler
   aws lambda update-function-code \
     --function-name task-manager-sandbox-notification-handler \
     --zip-file fileb://function.zip
   ```

4. **Confirm Subscription:**
   - Check email for AWS SNS confirmation
   - Click confirmation link

## Testing

Trigger a notification by:
1. Assigning a task to a user
2. Updating task status
3. Closing a task

All subscribers will receive the notification.

## Cost Comparison

| Service | Sandbox | Production |
|---------|---------|------------|
| SES | Free (200/day) | $0.10/1000 emails |
| SNS | $0.50/1M + $2/100K emails | Same |

SNS is more expensive but works in sandbox without verification.

## Rollback Plan

To revert to SES:
1. Restore `terraform/modules/ses/` from git
2. Update `terraform/main.tf` to use SES module
3. Restore original `lambda/notification-handler/index.js`
4. Run `terraform apply`

## Notes

- SNS sends to ALL subscribers (not user-specific)
- Message includes user email for context
- Subscribers must confirm email subscription
- Can add SMS notifications later
- Consider message filtering for targeted notifications
