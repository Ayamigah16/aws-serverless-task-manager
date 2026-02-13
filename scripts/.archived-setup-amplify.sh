#!/bin/bash
# Setup AWS Amplify Deployment
# Configures Amplify app with Terraform outputs

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Get infrastructure outputs
get_infra_outputs() {
    log_info "Fetching infrastructure outputs"
    
    local outputs
    outputs=$(get_terraform_outputs_json) || die "Failed to get Terraform outputs"
    
    USER_POOL_ID=$(echo "${outputs}" | jq -r '.cognito_user_pool_id.value')
    USER_POOL_CLIENT_ID=$(echo "${outputs}" | jq -r '.cognito_user_pool_client_id.value')
    APPSYNC_URL=$(echo "${outputs}" | jq -r '.appsync_graphql_url.value')
    
    # Validate outputs
    [ -n "${USER_POOL_ID}" ] || die "Could not get User Pool ID"
    [ -n "${USER_POOL_CLIENT_ID}" ] || die "Could not get User Pool Client ID"
    [ -n "${APPSYNC_URL}" ] || die "Could not get AppSync URL"
    
    log_debug "User Pool ID: ${USER_POOL_ID}"
    log_debug "User Pool Client ID: ${USER_POOL_CLIENT_ID}"
    log_debug "AppSync URL: ${APPSYNC_URL}"
}

# Create frontend environment file
create_frontend_env() {
    local env_file="${PROJECT_ROOT}/frontend/.env.local"
    
    log_info "Creating frontend environment file"
    
    cat > "${env_file}" <<EOF
NEXT_PUBLIC_USER_POOL_ID=${USER_POOL_ID}
NEXT_PUBLIC_USER_POOL_CLIENT_ID=${USER_POOL_CLIENT_ID}
NEXT_PUBLIC_APPSYNC_URL=${APPSYNC_URL}
NEXT_PUBLIC_AWS_REGION=${AWS_REGION}
