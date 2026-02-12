#!/bin/bash
# Create AppSync Resolvers Script
# Configures resolvers for GraphQL queries and mutations

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

# Request mapping template (pass everything to Lambda)
readonly REQUEST_TEMPLATE='{
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
readonly RESPONSE_TEMPLATE='$util.toJson($context.result)'

# Queries
readonly QUERIES=("getTask" "listTasks" "getMyTasks" "searchTasks" "getProject" "listProjects" "getSprint" "listSprints" "getSprintMetrics" "getUser" "listUsers" "getTaskComments" "getMyNotifications" "getProjectAnalytics" "getPresignedUploadUrl" "getPresignedDownloadUrl")

# Mutations
readonly MUTATIONS=("createTask" "updateTask" "deleteTask" "assignTask" "unassignTask" "closeTask" "createProject" "updateProject" "archiveProject" "createSprint" "startSprint" "completeSprint" "addComment" "updateComment" "deleteComment" "markNotificationRead" "markAllNotificationsRead" "attachFile" "deleteAttachment")

# ============================================================================
# FUNCTIONS
# ============================================================================

# Create resolvers for queries and mutations
create_resolvers() {
    local api_id="$1"

    log_info "Creating Query resolvers"
    for query in "${QUERIES[@]}"; do
      log_debug "Creating resolver: $query"
      aws appsync create-resolver \
        --api-id "$api_id" \
        --type-name Query \
        --field-name "$query" \
        --data-source-name LambdaDataSource \
        --request-mapping-template "$REQUEST_TEMPLATE" \
        --response-mapping-template "$RESPONSE_TEMPLATE" \
        --region "${AWS_REGION:-eu-west-1}" \
        2>/dev/null || log_debug "Resolver $query already exists"
    done

    log_info "Creating Mutation resolvers"
    for mutation in "${MUTATIONS[@]}"; do
      log_debug "Creating resolver: $mutation"
      aws appsync create-resolver \
        --api-id "$api_id" \
        --type-name Mutation \
        --field-name "$mutation" \
        --data-source-name LambdaDataSource \
        --request-mapping-template "$REQUEST_TEMPLATE" \
        --response-mapping-template "$RESPONSE_TEMPLATE" \
        --region "${AWS_REGION:-eu-west-1}" \
        2>/dev/null || log_debug "Resolver $mutation already exists"
    done
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    cd "$(dirname "$0")/.."

    log_info "Creating AppSync Resolvers"

    # Get AppSync API ID
    local api_id
    api_id=$(get_terraform_output "appsync_graphql_api_id")
    [ -z "$api_id" ] && die "AppSync API not found"

    log_info "API ID: $api_id"

    # Create resolvers
    create_resolvers "$api_id"

    log_success "Resolvers created successfully"
    log_info "Test with: aws appsync get-resolver --api-id $api_id --type-name Query --field-name getTask"
}

main "$@"
echo "  aws appsync list-resolvers --api-id $API_ID --type-name Query"
