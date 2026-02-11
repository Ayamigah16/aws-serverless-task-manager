#!/bin/bash
set -e

echo "🔗 Creating AppSync Resolvers..."

cd "$(dirname "$0")/.."

cd terraform
API_ID=$(terraform output -raw appsync_graphql_api_id 2>/dev/null)
cd ..

if [ -z "$API_ID" ]; then
  echo "❌ AppSync API not found"
  exit 1
fi

echo "📡 API ID: $API_ID"

# Request mapping template (pass everything to Lambda)
REQUEST_TEMPLATE='{
  "version": "2018-05-29",
  "operation": "Invoke",
  "payload": {
    "field": "$context.info.fieldName",
    "arguments": $util.toJson($context.arguments),
    "identity": $util.toJson($context.identity),
    "source": $util.toJson($context.source)
  }
}'

# Response mapping template (return Lambda result)
RESPONSE_TEMPLATE='$util.toJson($context.result)'

# Queries
QUERIES=("getTask" "listTasks" "getMyTasks" "searchTasks" "getProject" "listProjects" "getSprint" "listSprints" "getSprintMetrics" "getUser" "listUsers" "getTaskComments" "getMyNotifications" "getProjectAnalytics" "getPresignedUploadUrl" "getPresignedDownloadUrl")

# Mutations
MUTATIONS=("createTask" "updateTask" "deleteTask" "assignTask" "unassignTask" "closeTask" "createProject" "updateProject" "archiveProject" "createSprint" "startSprint" "completeSprint" "addComment" "updateComment" "deleteComment" "markNotificationRead" "markAllNotificationsRead" "attachFile" "deleteAttachment")

echo ""
echo "Creating Query resolvers..."
for query in "${QUERIES[@]}"; do
  echo "  - $query"
  aws appsync create-resolver \
    --api-id "$API_ID" \
    --type-name Query \
    --field-name "$query" \
    --data-source-name LambdaDataSource \
    --request-mapping-template "$REQUEST_TEMPLATE" \
    --response-mapping-template "$RESPONSE_TEMPLATE" \
    --region eu-west-1 \
    2>/dev/null || echo "    (already exists)"
done

echo ""
echo "Creating Mutation resolvers..."
for mutation in "${MUTATIONS[@]}"; do
  echo "  - $mutation"
  aws appsync create-resolver \
    --api-id "$API_ID" \
    --type-name Mutation \
    --field-name "$mutation" \
    --data-source-name LambdaDataSource \
    --request-mapping-template "$REQUEST_TEMPLATE" \
    --response-mapping-template "$RESPONSE_TEMPLATE" \
    --region eu-west-1 \
    2>/dev/null || echo "    (already exists)"
done

echo ""
echo "✅ Resolvers created successfully!"
echo ""
echo "Test with:"
echo "  aws appsync list-resolvers --api-id $API_ID --type-name Query"
