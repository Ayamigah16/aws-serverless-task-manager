#!/bin/bash

set -e

echo "🚀 Deploying SNS notification system..."

# Deploy Terraform changes
echo "📦 Applying Terraform changes..."
cd terraform
terraform apply -auto-approve

# Get SNS topic ARN
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn 2>/dev/null || echo "")

if [ -z "$SNS_TOPIC_ARN" ]; then
  echo "❌ Failed to get SNS topic ARN"
  exit 1
fi

echo "✅ SNS Topic ARN: $SNS_TOPIC_ARN"

# Deploy notification handler Lambda
echo "📦 Deploying notification handler Lambda..."
cd ../lambda/notification-handler

if [ ! -f function.zip ]; then
  echo "Creating Lambda deployment package..."
  zip -r function.zip index.js node_modules/ package*.json > /dev/null
fi

FUNCTION_NAME=$(cd ../../terraform && terraform output -raw notification_handler_lambda_name 2>/dev/null || echo "task-manager-sandbox-notification-handler")

aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://function.zip \
  --no-cli-pager

echo "✅ Lambda deployed successfully"

echo ""
echo "🎉 SNS migration complete!"
echo ""
echo "⚠️  IMPORTANT: Check your email and confirm SNS subscription"
echo "   AWS will send a confirmation email to the addresses in notification_emails"
echo ""
