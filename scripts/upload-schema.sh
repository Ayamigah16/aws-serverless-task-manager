#!/bin/bash
# Upload AppSync Schema Script
# Uploads GraphQL schema to AppSync API

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Upload schema to AppSync
upload_schema() {
    local api_id="$1"

    log_info "Uploading schema to AppSync API: $api_id"

    aws appsync start-schema-creation \
      --api-id "$api_id" \
      --definition "$(cat schema.graphql | base64)"

    log_success "Schema upload initiated"
    log_info "Schema creation is asynchronous. Check status with:"
    log_info "  aws appsync get-schema-creation-status --api-id $api_id"
    log_info "Once complete, configure resolvers or run: ./scripts/create-resolvers.sh"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    cd "$(dirname "$0")/.."

    log_info "Uploading AppSync GraphQL Schema"

    # Check if schema file exists
    [ ! -f "schema.graphql" ] && die "schema.graphql not found"

    # Get AppSync API ID
    local api_id
    api_id=$(get_terraform_output "appsync_api_id")
    [ -z "$api_id" ] && die "AppSync API not deployed. Run 'terraform apply' first."

    # Upload schema
    upload_schema "$api_id"
}

main "$@"
