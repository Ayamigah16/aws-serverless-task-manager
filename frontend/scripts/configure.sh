#!/bin/bash
set -e

echo "🚀 Configuring Frontend with Lambda Endpoints..."

cd "$(dirname "$0")/.."

TERRAFORM_DIR="../terraform"

if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "❌ Terraform directory not found"
  exit 1
fi

cd "$TERRAFORM_DIR"

echo "📡 Fetching Terraform outputs..."

API_ENDPOINT=$(terraform output -raw api_gateway_url 2>/dev/null)
USER_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
USER_POOL_CLIENT_ID=$(terraform output -raw cognito_user_pool_client_id 2>/dev/null)
AWS_REGION=$(terraform output -raw region 2>/dev/null)
APPSYNC_ENDPOINT=$(terraform output -raw appsync_graphql_endpoint 2>/dev/null || echo "")
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "")

cd - > /dev/null

cat > .env.local <<EOF
NEXT_PUBLIC_USER_POOL_ID=$USER_POOL_ID
NEXT_PUBLIC_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID
NEXT_PUBLIC_APPSYNC_ENDPOINT=$APPSYNC_ENDPOINT
NEXT_PUBLIC_API_ENDPOINT=$API_ENDPOINT
NEXT_PUBLIC_S3_BUCKET=$S3_BUCKET
NEXT_PUBLIC_AWS_REGION=$AWS_REGION
EOF

echo ""
echo "✅ Frontend configured successfully!"
echo ""
echo "Configuration:"
echo "  API Gateway: $API_ENDPOINT"
echo "  User Pool: $USER_POOL_ID"
echo "  Client ID: ${USER_POOL_CLIENT_ID:0:20}..."
echo "  Region: $AWS_REGION"
[ -n "$APPSYNC_ENDPOINT" ] && echo "  AppSync: $APPSYNC_ENDPOINT"
[ -n "$S3_BUCKET" ] && echo "  S3 Bucket: $S3_BUCKET"
echo ""
echo "Run 'npm run dev' to start the development server"
