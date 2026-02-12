#!/bin/bash
# Check User Groups Script
# Shows which groups a user belongs to

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Validate input
    if [ -z "${1:-}" ]; then
      die "Usage: ./check-user-groups.sh <user-email>"
    fi

    local user_email="$1"
    local user_pool_id
    user_pool_id=$(get_terraform_output "cognito_user_pool_id")

    log_info "Checking groups for: $user_email"

    aws cognito-idp admin-list-groups-for-user \
      --user-pool-id "$user_pool_id" \
      --username "$user_email" \
      --query "Groups[].GroupName" \
      --output table
}

main "$@"
