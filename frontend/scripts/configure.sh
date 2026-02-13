#!/bin/bash
# Frontend Configuration Script
# Configures frontend with backend endpoints from Terraform

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Fetch Terraform outputs
fetch_terraform_outputs() {
    local terraform_dir="../terraform"

    [ ! -d "$terraform_dir" ] && die "Terraform directory not found"

    cd "$terraform_dir"

    log_info "Fetching Terraform outputs"

    USER_POOL_ID=$(get_terraform_output "cognito_user_pool_id")
    USER_POOL_CLIENT_ID=$(get_terraform_output "cognito_user_pool_client_id")
    AWS_REGION=$(get_terraform_output "region")
    APPSYNC_ENDPOINT=$(get_terraform_output "appsync_graphql_url")
    S3_BUCKET=$(get_terraform_output "s3_bucket_name" 2>/dev/null || echo "")

    cd - > /dev/null
}

# Create environment configuration file
create_env_file() {
    cat > .env.local <<EOF
NEXT_PUBLIC_COGNITO_USER_POOL_ID=$USER_POOL_ID
NEXT_PUBLIC_USER_POOL_CLIENT_ID=$USER_POOL_CLIENT_ID
NEXT_PUBLIC_APPSYNC_ENDPOINT=$APPSYNC_ENDPOINT
NEXT_PUBLIC_S3_BUCKET=$S3_BUCKET
NEXT_PUBLIC_AWS_REGION=$AWS_REGION
EOF
}

# Display configuration summary
show_summary() {
    log_success "Frontend configured"
    log_info "AppSync GraphQL: $APPSYNC_ENDPOINT"
    log_info "User Pool: $USER_POOL_ID"
    log_info "Client ID: ${USER_POOL_CLIENT_ID:0:20}..."
    log_info "Region: $AWS_REGION"
    [ -n "$S3_BUCKET" ] && log_info "S3 Bucket: $S3_BUCKET"
    log_info "Run 'npm run dev' to start development server"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    cd "$(dirname "$0")/.."

    # Fetch outputs from Terraform
    fetch_terraform_outputs

    # Create .env.local file
    create_env_file

    # Show summary
    show_summary
}

main "$@"
