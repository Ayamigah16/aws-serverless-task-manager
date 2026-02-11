#!/bin/bash
set -e

echo "📤 Uploading AppSync GraphQL Schema..."

cd "$(dirname "$0")/.."

if [ ! -f "schema.graphql" ]; then
  echo "❌ schema.graphql not found"
  exit 1
fi

cd terraform

API_ID=$(terraform output -raw appsync_graphql_api_id 2>/dev/null)

if [ -z "$API_ID" ]; then
  echo "❌ AppSync API not deployed. Run 'terraform apply' first."
  exit 1
fi

cd ..

echo "📡 Uploading schema to AppSync API: $API_ID"

aws appsync start-schema-creation \
  --api-id "$API_ID" \
  --definition "$(cat schema.graphql | base64)"

echo ""
echo "✅ Schema upload initiated!"
echo ""
echo "Note: Schema creation is asynchronous. Check status with:"
echo "  aws appsync get-schema-creation-status --api-id $API_ID"
echo ""
echo "Once complete, configure resolvers in AWS Console or run:"
echo "  aws appsync create-resolver --api-id $API_ID ..."
