# Automatic Member Notifications

## How It Works

When a user signs up:
1. Pre-signup Lambda validates email domain
2. Automatically subscribes user to SNS topic with email filter
3. User receives SNS confirmation email
4. User confirms subscription
5. User receives notifications for tasks assigned to them

## Setup

### 1. Optional: Add Admin Emails (receive all notifications)

In `terraform/terraform.tfvars`:
```hcl
notification_emails = ["admin@amalitech.com"]  # Optional
```

### 2. Deploy
```bash
cd terraform && terraform apply

cd ../lambda/pre-signup-trigger
zip -r function.zip index.js node_modules/ package*.json
aws lambda update-function-code \
  --function-name task-manager-sandbox-pre-signup \
  --zip-file fileb://function.zip
```

### 3. User Signup Flow
1. User signs up with `john@amalitech.com`
2. Pre-signup Lambda creates SNS subscription for john
3. John receives 2 emails:
   - Cognito OTP verification code
   - SNS subscription confirmation
4. John enters OTP to verify account
5. John clicks SNS confirmation link
6. John now receives notifications for assigned tasks

## Notification Flow

**Task Assignment:**
```
Admin assigns task to john@amalitech.com
  ↓
SNS publishes with MessageAttributes: { email: "john@amalitech.com" }
  ↓
Only John's subscription matches filter
  ↓
John receives email notification
```

## No Manual Management

- ✅ Members auto-subscribe on signup
- ✅ Each member only receives their notifications
- ✅ No need to update Terraform for new members
- ✅ Scales automatically

## Admin Notifications

Admins in `notification_emails` receive ALL notifications (no filter).

## Testing

1. Sign up new user: `test@amalitech.com`
2. Check email for SNS confirmation
3. Click confirmation link
4. Assign task to test user
5. Test user receives notification
