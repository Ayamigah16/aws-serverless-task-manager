# AWS Account Preparation Guide

## 📋 Overview

This guide outlines the steps to prepare your AWS Sandbox account for the Serverless Task Management System deployment.

## ✅ Pre-Deployment Checklist

### 1. Account Access Verification

#### Verify Account Access
```bash
# Check current AWS identity
aws sts get-caller-identity

# Expected output should show your account ID and user ARN
```

#### Document Account Information
- **Account ID**: ____________
- **Region**: ____________ (Recommended: us-east-1)
- **Environment**: Sandbox
- **Account Owner**: ____________

### 2. IAM Permissions

#### Required Permissions
Ensure your IAM user/role has permissions for:
- ✅ IAM (roles, policies)
- ✅ Lambda
- ✅ API Gateway
- ✅ DynamoDB
- ✅ Cognito
- ✅ EventBridge
- ✅ SES
- ✅ S3
- ✅ CloudWatch
- ✅ CloudTrail
- ✅ Systems Manager (Parameter Store)
- ✅ X-Ray

#### Verify Permissions
```bash
# Test creating a test S3 bucket (delete after)
aws s3 mb s3://test-permissions-$(date +%s)
aws s3 rb s3://test-permissions-$(date +%s)
```

### 3. Service Quotas

#### Check Current Limits
```bash
# Lambda concurrent executions
aws service-quotas get-service-quota \
  --service-code lambda \
  --quota-code L-B99A9384

# API Gateway requests per second
aws service-quotas get-service-quota \
  --service-code apigateway \
  --quota-code L-8A5B8E43
```

#### Request Increases (if needed)
- Lambda concurrent executions: Default 1000
- API Gateway throttle limit: Default 10000 req/sec
- DynamoDB tables: Default 2500 per region
- SES sending rate: Request production access

### 4. Enable AWS Services

#### Enable CloudTrail
```bash
# Create CloudTrail trail
aws cloudtrail create-trail \
  --name task-manager-audit-trail \
  --s3-bucket-name task-manager-cloudtrail-logs-$(aws sts get-caller-identity --query Account --output text)

# Start logging
aws cloudtrail start-logging --name task-manager-audit-trail
```

#### Enable AWS Config
```bash
# Create configuration recorder
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::ACCOUNT_ID:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig \
  --recording-group allSupported=true,includeGlobalResourceTypes=true

# Start recording
aws configservice start-configuration-recorder --configuration-recorder-name default
```

#### Enable Cost Explorer
- Navigate to AWS Console → Billing → Cost Explorer
- Click "Enable Cost Explorer"
- Wait 24 hours for data to populate

### 5. Set Up Billing Alerts

#### Create SNS Topic for Alerts
```bash
# Create SNS topic
aws sns create-topic --name billing-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:billing-alerts \
  --protocol email \
  --notification-endpoint your-email@amalitech.com
```

#### Create CloudWatch Billing Alarm
```bash
# Create alarm for $100 threshold
aws cloudwatch put-metric-alarm \
  --alarm-name billing-alert-100 \
  --alarm-description "Alert when charges exceed $100" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:ACCOUNT_ID:billing-alerts
```

### 6. SES Configuration

#### Verify Email Address
```bash
# Verify sender email
aws ses verify-email-identity --email-address noreply@amalitech.com

# Check verification status
aws ses get-identity-verification-attributes --identities noreply@amalitech.com
```

#### Request Production Access (if needed)
1. Navigate to SES Console
2. Click "Request Production Access"
3. Fill out the form:
   - Use case: Task management notifications
   - Expected sending volume: < 1000 emails/day
   - Bounce/complaint handling: Automated via EventBridge

### 7. Region Selection

#### Recommended Region: us-east-1 (N. Virginia)

**Reasons:**
- Most AWS services available
- Lowest latency for global access
- Cost-effective
- Cognito Hosted UI support

#### Set Default Region
```bash
# Add to ~/.bashrc or ~/.zshrc
export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1
```

### 8. Security Baseline

#### Enable MFA for Root Account
1. Sign in as root user
2. Navigate to IAM → Security Credentials
3. Enable MFA device

#### Create IAM Admin User (if not exists)
```bash
# Create admin group
aws iam create-group --group-name Admins

# Attach admin policy
aws iam attach-group-policy \
  --group-name Admins \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create user
aws iam create-user --user-name admin-user

# Add user to group
aws iam add-user-to-group --user-name admin-user --group-name Admins
```

#### Enable CloudTrail Logging
- Ensure CloudTrail is logging all regions
- Enable log file validation
- Configure S3 bucket with encryption

### 9. Cost Optimization

#### Enable AWS Budgets
```bash
# Create budget
aws budgets create-budget \
  --account-id ACCOUNT_ID \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

#### Tag Strategy
All resources will be tagged with:
- `Project`: task-manager
- `Environment`: sandbox
- `ManagedBy`: terraform
- `Owner`: devops-team
- `CostCenter`: engineering

### 10. Network Configuration

#### VPC (Optional for this project)
This project uses serverless services that don't require VPC configuration. However, for enhanced security:

```bash
# Create VPC (optional)
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Create VPC endpoints for AWS services (optional)
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxxxx \
  --service-name com.amazonaws.us-east-1.dynamodb \
  --route-table-ids rtb-xxxxx
```

## 📊 Resource Limits to Monitor

| Service | Limit | Current Usage | Action Required |
|---------|-------|---------------|-----------------|
| Lambda Functions | 1000 | 0 | None |
| DynamoDB Tables | 2500 | 0 | None |
| API Gateway APIs | 600 | 0 | None |
| Cognito User Pools | 1000 | 0 | None |
| SES Daily Sending | 200 (sandbox) | 0 | Request increase |

## 🔍 Verification Commands

### Verify All Services Enabled
```bash
# CloudTrail
aws cloudtrail describe-trails

# Config
aws configservice describe-configuration-recorders

# SES
aws ses get-account-sending-enabled

# Cost Explorer
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```

## 📝 Documentation

### Record the Following Information

Create a file `terraform/environments/sandbox/account-info.txt` (DO NOT COMMIT):

```
AWS Account ID: ____________
Region: ____________
CloudTrail Name: ____________
Config Recorder: ____________
SNS Topic ARN (Billing): ____________
SES Verified Email: ____________
Admin User ARN: ____________
```

## ✅ Final Checklist

Before proceeding to infrastructure deployment:

- [ ] AWS CLI configured and tested
- [ ] Account ID documented
- [ ] Region selected and configured
- [ ] IAM permissions verified
- [ ] CloudTrail enabled
- [ ] AWS Config enabled
- [ ] Billing alerts configured
- [ ] SES email verified
- [ ] Service quotas checked
- [ ] Security baseline implemented
- [ ] Cost optimization enabled
- [ ] All verification commands successful

## 🚀 Next Steps

Once all items are checked:
1. Proceed to Phase 2: Terraform Infrastructure Foundation
2. Initialize Terraform remote state
3. Begin infrastructure deployment

## 📞 Support

For AWS account issues:
- AWS Support Center
- Account administrator
- DevOps team lead

---

**Last Updated**: [Date]  
**Prepared By**: DevSecOps Team
