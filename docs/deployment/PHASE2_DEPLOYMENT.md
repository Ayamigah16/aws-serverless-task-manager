# Phase 2 Deployment Guide

## Prerequisites

1. AWS CLI configured with credentials
2. Terraform >= 1.5.0 installed
3. Appropriate IAM permissions

## Step 1: Set Up Remote State

```bash
cd /home/weirdo/dev/aws-serverless-task-manager
./scripts/setup-remote-state.sh
```

This creates:
- S3 bucket: `task-manager-terraform-state`
- DynamoDB table: `task-manager-terraform-locks`

## Step 2: Build Lambda Functions

Before deploying, create placeholder Lambda zip files:

```bash
# Pre Sign-Up Lambda
cd lambda/pre-signup-trigger
zip -r function.zip package.json
cd ../..

# Task API Lambda
cd lambda/task-api
zip -r function.zip package.json
cd ../..

# Notification Handler Lambda
cd lambda/notification-handler
zip -r function.zip package.json
cd ../..
```

## Step 3: Update Configuration

Edit `terraform/terraform.tfvars`:
- Set `admin_email` to your email
- Set `ses_sender_email` to verified SES email

## Step 4: Initialize Terraform

```bash
cd terraform
terraform init
```

## Step 5: Plan Deployment

```bash
terraform plan
```

Review the resources to be created.

## Step 6: Deploy Infrastructure

```bash
terraform apply
```

Type `yes` to confirm.

## Step 7: Verify Deployment

```bash
terraform output
```

Save the outputs for frontend configuration.

## Resources Created

- DynamoDB table with GSIs
- Cognito User Pool with groups
- 3 Lambda functions with IAM roles
- API Gateway with Cognito authorizer
- EventBridge event bus with rules
- SES email identity
- CloudWatch log groups

## Next Steps

After successful deployment:
1. Verify SES email in AWS Console
2. Create test users in Cognito
3. Proceed to Phase 3: Lambda implementation
