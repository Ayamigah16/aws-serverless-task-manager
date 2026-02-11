#!/bin/bash

set -e

echo "🚀 Setting up AWS Amplify deployment..."

# Get Terraform outputs
cd terraform
OUTPUTS=$(terraform output -json)

USER_POOL_ID=$(echo $OUTPUTS | jq -r '.cognito_user_pool_id.value')
USER_POOL_CLIENT_ID=$(echo $OUTPUTS | jq -r '.cognito_user_pool_client_id.value')
APPSYNC_URL=$(echo $OUTPUTS | jq -r '.appsync_graphql_url.value')
AWS_REGION=$(echo $OUTPUTS | jq -r '.aws_region.value')

cd ..

echo "📝 Environment Variables:"
echo "  NEXT_PUBLIC_USER_POOL_ID=$USER_POOL_ID"
echo "  NEXT_PUBLIC_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID"
echo "  NEXT_PUBLIC_APPSYNC_URL=$APPSYNC_URL"
echo "  NEXT_PUBLIC_AWS_REGION=$AWS_REGION"
echo ""

# Create .env.local for local development
cat > frontend/.env.local <<EOF
NEXT_PUBLIC_USER_POOL_ID=$USER_POOL_ID
NEXT_PUBLIC_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID
NEXT_PUBLIC_APPSYNC_URL=$APPSYNC_URL
NEXT_PUBLIC_AWS_REGION=$AWS_REGION
EOF

echo "✅ Created frontend/.env.local"
echo ""

# Create Amplify app
echo "🔧 Creating Amplify app..."

APP_NAME="task-manager-frontend"

# Check if app exists
APP_ID=$(aws amplify list-apps --query "apps[?name=='$APP_NAME'].appId" --output text 2>/dev/null || echo "")

if [ -z "$APP_ID" ]; then
  echo "Creating new Amplify app..."
  
  APP_ID=$(aws amplify create-app \
    --name "$APP_NAME" \
    --platform WEB \
    --environment-variables \
      NEXT_PUBLIC_USER_POOL_ID="$USER_POOL_ID" \
      NEXT_PUBLIC_USER_POOL_CLIENT_ID="$USER_POOL_CLIENT_ID" \
      NEXT_PUBLIC_APPSYNC_URL="$APPSYNC_URL" \
      NEXT_PUBLIC_AWS_REGION="$AWS_REGION" \
    --query 'app.appId' \
    --output text)
  
  echo "✅ Created Amplify app: $APP_ID"
else
  echo "✅ Amplify app already exists: $APP_ID"
  
  # Update environment variables
  aws amplify update-app \
    --app-id "$APP_ID" \
    --environment-variables \
      NEXT_PUBLIC_USER_POOL_ID="$USER_POOL_ID" \
      NEXT_PUBLIC_USER_POOL_CLIENT_ID="$USER_POOL_CLIENT_ID" \
      NEXT_PUBLIC_APPSYNC_URL="$APPSYNC_URL" \
      NEXT_PUBLIC_AWS_REGION="$AWS_REGION" \
    --no-cli-pager > /dev/null
  
  echo "✅ Updated environment variables"
fi

echo ""
echo "🎉 Amplify setup complete!"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Connect to GitHub repository:"
echo "   aws amplify create-branch --app-id $APP_ID --branch-name main --framework Next.js"
echo ""
echo "2. Or deploy manually:"
echo "   cd frontend"
echo "   npm run build"
echo "   zip -r build.zip .next public package.json"
echo "   aws amplify create-deployment --app-id $APP_ID --branch-name main"
echo ""
echo "3. View app:"
echo "   https://console.aws.amazon.com/amplify/home?region=$AWS_REGION#/$APP_ID"
echo ""
