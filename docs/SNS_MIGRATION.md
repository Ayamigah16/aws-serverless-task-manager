# SNS Notification Migration

Switched from SES to SNS for notifications in sandbox environment to avoid SES verification requirements.

## Changes Made

### Infrastructure
- **Removed**: `terraform/modules/ses/` - SES module
- **Added**: `terraform/modules/sns/` - SNS module with email subscriptions
- **Updated**: Lambda IAM policies to use `sns:Publish` instead of `ses:SendEmail`

### Lambda Functions
- **notification-handler**: Rewritten to use SNS instead of SES
  - Uses `SNSClient` and `PublishCommand`
  - Sends notifications to SNS topic (all subscribers receive them)
  - Fixed DynamoDB queries to not use shared layer

### Configuration
- **terraform/variables.tf**: Changed `ses_sender_email` to `notification_emails` (list)
- **terraform/terraform.tfvars**: Updated to use `notification_emails = ["admin@amalitech.com"]`

## Deployment

```bash
# Option 1: Use deployment script
./scripts/deploy-sns.sh

# Option 2: Manual deployment
cd terraform
terraform apply

cd ../lambda/notification-handler
zip -r function.zip index.js node_modules/ package*.json
aws lambda update-function-code \
  --function-name task-manager-sandbox-notification-handler \
  --zip-file fileb://function.zip
```

## Post-Deployment

1. **Confirm SNS Subscription**: Check email inbox for AWS SNS subscription confirmation
2. **Click confirmation link** in the email
3. **Test notifications**: Assign a task to trigger notification

## How It Works

- All notifications go to SNS topic
- SNS topic fans out to all email subscribers
- Each subscriber receives all notifications (not user-specific)
- Notification message includes user email for context

## Differences from SES

| Feature | SES | SNS |
|---------|-----|-----|
| Recipient | Individual user emails | All subscribers |
| Verification | Required in sandbox | Not required |
| Cost | $0.10/1000 emails | $0.50/1M notifications + $2/100K emails |
| Setup | Complex | Simple |

## Future Improvements

- Filter notifications by user preference
- Add SMS notifications
- Implement SNS message filtering for targeted notifications
