# Member Notifications with SNS

## How It Works

Each team member receives notifications **only for tasks assigned to them** using SNS message filtering.

## Setup

### 1. Add All Team Member Emails

In `terraform/terraform.tfvars`:
```hcl
notification_emails = [
  "admin@amalitech.com",
  "john@amalitech.com",
  "jane@amalitech.com",
  "bob@amalitech.com"
]
```

### 2. Deploy
```bash
./scripts/deploy-sns.sh
```

### 3. Each Member Confirms Subscription
- Each email receives AWS SNS confirmation
- Each person clicks their confirmation link
- Filter policy automatically applied

## Notification Rules

**Members receive notifications when:**
- Task assigned to them
- Task status updated (if they're assigned)
- Task closed (if they're assigned)

**Admins receive notifications for:**
- All tasks they created
- Tasks they're assigned to

## Example Flow

1. Admin assigns task to `john@amalitech.com`
2. SNS publishes with `MessageAttributes: { email: "john@amalitech.com" }`
3. Only John's subscription receives it (filter matches)
4. John gets email notification

## Adding New Members

```bash
# 1. Add email to terraform.tfvars
notification_emails = [..., "newmember@amalitech.com"]

# 2. Apply changes
cd terraform && terraform apply

# 3. New member confirms subscription
```

## Removing Members

```bash
# 1. Remove email from terraform.tfvars
# 2. Apply changes
cd terraform && terraform apply

# Subscription automatically deleted
```

## Technical Details

**SNS Filter Policy:**
```json
{
  "email": ["john@amalitech.com"]
}
```

**Message Attributes:**
```javascript
MessageAttributes: {
  email: {
    DataType: 'String',
    StringValue: userEmail  // Assigned user's email
  }
}
```

Only subscriptions with matching filter receive the message.
