#!/bin/bash
# List Users Script
# Shows all users with their IDs for task assignment

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Get user pool ID from parameter or environment
    local user_pool_id="${COGNITO_USER_POOL_ID:-${1:-}}"

    if [ -z "$user_pool_id" ]; then
      die "User Pool ID required. Usage: $0 <user-pool-id> or set COGNITO_USER_POOL_ID"
    fi

    log_info "Listing users in pool: ${user_pool_id}"

    aws cognito-idp list-users \
      --user-pool-id "${user_pool_id}" \
      --region "${AWS_REGION}" \
      --query 'Users[*].[Username, Attributes[?Name==`sub`].Value | [0], Attributes[?Name==`email`].Value | [0]]' \
      --output table

    log_info "Use the User ID (middle column) for task assignments"
}

main "$@"
