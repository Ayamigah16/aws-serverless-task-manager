#!/bin/bash
# Create GitHub Token Secret in AWS Secrets Manager
# This script securely stores the GitHub token outside of Terraform

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

DEFAULT_SECRET_NAME="task-manager-github-token"
REGION="${AWS_REGION:-eu-west-1}"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Check if secret exists
secret_exists() {
    local secret_name="$1"
    aws secretsmanager describe-secret \
        --secret-id "$secret_name" \
        --region "$REGION" \
        --output json 2>/dev/null || return 1
    return 0
}

# Create or update secret
create_or_update_secret() {
    local secret_name="$1"
    local token="$2"

    if secret_exists "$secret_name"; then
        log_info "Updating existing secret: $secret_name"
        aws secretsmanager put-secret-value \
            --secret-id "$secret_name" \
            --secret-string "$token" \
            --region "$REGION" \
            --output json > /dev/null
        log_success "Secret updated successfully"
    else
        log_info "Creating new secret: $secret_name"
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --description "GitHub personal access token for AWS Amplify deployments" \
            --secret-string "$token" \
            --region "$REGION" \
            --tags "Key=Environment,Value=production" \
                   "Key=ManagedBy,Value=Script" \
                   "Key=Purpose,Value=AmplifyDeployment" \
            --output json > /dev/null
        log_success "Secret created successfully"
    fi
}

# Validate GitHub token format
validate_token() {
    local token="$1"

    if [[ ! "$token" =~ ^(ghp_|github_pat_)[A-Za-z0-9_]+ ]]; then
        log_warn "Token format looks unusual. GitHub tokens usually start with 'ghp_' or 'github_pat_'" >&2
        read -p "Continue anyway? [y/N]: " confirm >&2
        [[ "$confirm" =~ ^[Yy]$ ]] || die "Aborted by user"
    fi
}

# Prompt for GitHub token
prompt_token() {
    echo "" >&2
    log_info "═══════════════════════════════════════════════════════════" >&2
    log_info "GitHub Personal Access Token Required" >&2
    log_info "═══════════════════════════════════════════════════════════" >&2
    echo "" >&2
    log_info "You need a GitHub Personal Access Token with 'repo' scope." >&2
    log_info "Create one at: https://github.com/settings/tokens/new" >&2
    echo "" >&2
    log_info "Required scopes:" >&2
    log_info "  ✓ repo (Full control of private repositories)" >&2
    echo "" >&2
    log_warn "Your token will be stored securely in AWS Secrets Manager" >&2
    log_warn "It will NOT appear in any Terraform files or state" >&2
    echo "" >&2

    read -sp "Enter GitHub Token: " TOKEN >&2
    echo "" >&2

    if [[ -z "$TOKEN" ]]; then
        die "Token cannot be empty"
    fi

    validate_token "$TOKEN"
    echo "$TOKEN"
}

# Main execution
main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    log_info "GitHub Token Secret Setup"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Check AWS credentials
    check_aws_auth

    # Get secret name
    read -p "Secret name [${DEFAULT_SECRET_NAME}]: " SECRET_NAME
    SECRET_NAME="${SECRET_NAME:-${DEFAULT_SECRET_NAME}}"

    # Get GitHub token
    TOKEN=$(prompt_token)

    # Create or update secret
    create_or_update_secret "$SECRET_NAME" "$TOKEN"

    echo ""
    log_success "═══════════════════════════════════════════════════════════"
    log_success "Secret Setup Complete!"
    log_success "═══════════════════════════════════════════════════════════"
    echo ""
    log_info "Secret Details:"
    log_info "  Name: $SECRET_NAME"
    log_info "  Region: $REGION"
    echo ""
    log_info "Next Steps:"
    log_info "  1. Update terraform.tfvars with:"
    log_info "     github_secret_name = \"$SECRET_NAME\""
    echo ""
    log_info "  2. Deploy Amplify with Terraform:"
    log_info "     cd terraform && terraform apply"
    echo ""
    log_info "To rotate the token later, run this script again."
    echo ""
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Handle script arguments
case "${1:-}" in
    -h|--help)
        cat << EOF
Usage: $0 [OPTIONS]

Create or update GitHub token in AWS Secrets Manager for Amplify deployments.

Options:
    -h, --help     Show this help message
    --secret-name  Name of the secret (default: $DEFAULT_SECRET_NAME)
    --region       AWS region (default: $REGION)

Environment Variables:
    AWS_REGION     Override default AWS region

Examples:
    # Interactive mode (recommended)
    $0

    # Specify secret name
    $0 --secret-name my-github-token

    # Use different region
    AWS_REGION=us-east-1 $0

EOF
        exit 0
        ;;
    --secret-name)
        DEFAULT_SECRET_NAME="$2"
        shift 2
        ;;
    --region)
        REGION="$2"
        shift 2
        ;;
esac

main "$@"
