#!/bin/bash
# Create Admin User Script
# Creates a Cognito admin user and adds to Admins group

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Get User Pool ID from Terraform or prompt user
get_user_pool_id() {
    local pool_id

    pool_id=$(get_terraform_output "cognito_user_pool_id" 2>/dev/null) || {
        log_warn "Could not get User Pool ID from Terraform"
        log_info "Ensure 'terraform apply' has been run"
        pool_id=$(prompt_input "Enter User Pool ID")
    }

    echo "${pool_id}"
}

# Validate organization email domain
validate_org_email() {
    local email="$1"

    if ! validate_email "${email}"; then
        return 1
    fi

    if [[ ! "${email}" =~ @(amalitech\.com|amalitechtraining\.org)$ ]]; then
        log_error "Invalid email domain. Must be @amalitech.com or @amalitechtraining.org"
        return 1
    fi

    return 0
}

# Check if user exists in Cognito
user_exists() {
    local pool_id="$1"
    local username="$2"

    aws cognito-idp admin-get-user \
        --user-pool-id "${pool_id}" \
        --username "${username}" \
        --region "${AWS_REGION}" \
        --no-cli-pager &>/dev/null
}

# Create Cognito user
create_user() {
    local pool_id="$1"
    local email="$2"
    local temp_password="$3"

    log_info "Creating user: ${email}"

    if user_exists "${pool_id}" "${email}"; then
        die "User already exists: ${email}"
    fi

    aws cognito-idp admin-create-user \
        --user-pool-id "${pool_id}" \
        --username "${email}" \
        --user-attributes \
            Name=email,Value="${email}" \
            Name=email_verified,Value=true \
        --temporary-password "${temp_password}" \
        --region "${AWS_REGION}" \
        --no-cli-pager &>/dev/null || die "Failed to create user"

    log_success "User created"
}

# Add user to Admins group
add_to_admins() {
    local pool_id="$1"
    local email="$2"

    log_info "Adding to Admins group"

    aws cognito-idp admin-add-user-to-group \
        --user-pool-id "${pool_id}" \
        --username "${email}" \
        --group-name Admins \
        --region "${AWS_REGION}" \
        --no-cli-pager || die "Failed to add to Admins group"

    log_success "Added to Admins group"
}

# Set permanent password
set_permanent_password() {
    local pool_id="$1"
    local email="$2"
    local password="$3"

    log_info "Setting permanent password"

    aws cognito-idp admin-set-user-password \
        --user-pool-id "${pool_id}" \
        --username "${email}" \
        --password "${password}" \
        --permanent \
        --region "${AWS_REGION}" \
        --no-cli-pager || die "Failed to set permanent password"

    log_success "Permanent password set"
}

# Generate secure random password
generate_password() {
    openssl rand -base64 12 | tr -d '\n' | head -c 12
    echo "@Aa1"
}

# Validate password meets Cognito requirements
validate_password() {
    local password="$1"
    [ ${#password} -ge 8 ] || {
        log_error "Password must be at least 8 characters"
        return 1
    }
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Create Admin User"
    echo ""

    # Check prerequisites
    require_commands aws terraform openssl
    check_aws_auth

    # Get User Pool ID
    local user_pool_id
    user_pool_id=$(get_user_pool_id)
    log_info "User Pool: ${user_pool_id}"
    echo ""

    # Get email
    local email
    email=$(prompt_input "Enter admin email" validate_org_email)
    echo ""

    # Get temporary password
    local temp_password
    if confirm "Generate random temporary password?" "y"; then
        temp_password=$(generate_password)
        log_info "Temporary password: ${temp_password}"
    else
        while true; do
            read -r -s -p "Enter temporary password: " temp_password
            echo ""
            validate_password "${temp_password}" && break
        done
    fi
    echo ""

    # Optionally set permanent password
    local perm_password=""
    if confirm "Set permanent password now?" "n"; then
        while true; do
            read -r -s -p "Enter permanent password: " perm_password
            echo ""
            read -r -s -p "Confirm password: " perm_password_confirm
            echo ""

            if [ "${perm_password}" != "${perm_password_confirm}" ]; then
                log_error "Passwords do not match"
                continue
            fi

            validate_password "${perm_password}" && break
        done
    fi
    echo ""

    # Confirm operation
    log_info "Summary:"
    echo "  Email: ${email}"
    echo "  User Pool: ${user_pool_id}"
    echo "  Group: Admins"
    echo ""

    confirm "Create admin user?" "y" || {
        log_info "Cancelled"
        exit 0
    }
    echo ""

    # Create user and configure
    create_user "${user_pool_id}" "${email}" "${temp_password}"
    add_to_admins "${user_pool_id}" "${email}"

    if [ -n "${perm_password}" ]; then
        set_permanent_password "${user_pool_id}" "${email}" "${perm_password}"
    fi

    echo ""
    log_success "Admin user created successfully"
    echo ""
    echo "Email: ${email}"
    if [ -n "${perm_password}" ]; then
        echo "Permanent password: (set)"
    else
        echo "Temporary password: ${temp_password}"
        log_info "User must change password on first login"
    fi
}

main "$@"
