#!/bin/bash

# Create Admin User Script
# Creates a Cognito admin user and adds to Admins group

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
error_exit() { log_error "$1"; exit "${2:-1}"; }

# Get User Pool ID from Terraform
get_user_pool_id() {
    local pool_id=""
    if [[ -f terraform/terraform.tfstate ]]; then
        pool_id=$(cd terraform && terraform output -raw cognito_user_pool_id 2>/dev/null) || pool_id=""
    fi
    
    if [[ -z "${pool_id}" ]]; then
        log_error "Could not get User Pool ID from Terraform"
        read -p "Enter User Pool ID manually: " pool_id
    fi
    
    echo "${pool_id}"
}

# Validate email domain
validate_email() {
    local email="$1"
    if [[ ! "${email}" =~ @(amalitech\.com|amalitechtraining\.org)$ ]]; then
        error_exit "Invalid email domain. Must be @amalitech.com or @amalitechtraining.org"
    fi
}

# Check if user exists
user_exists() {
    local pool_id="$1"
    local username="$2"
    aws cognito-idp admin-get-user \
        --user-pool-id "${pool_id}" \
        --username "${username}" \
        --region eu-west-1 &>/dev/null
}

# Create user
create_user() {
    local pool_id="$1"
    local email="$2"
    local temp_password="$3"
    
    log_info "Creating user: ${email}"
    
    if user_exists "${pool_id}" "${email}"; then
        log_error "User already exists: ${email}"
        return 1
    fi
    
    if ! aws cognito-idp admin-create-user \
        --user-pool-id "${pool_id}" \
        --username "${email}" \
        --user-attributes \
            Name=email,Value="${email}" \
            Name=email_verified,Value=true \
        --temporary-password "${temp_password}" \
        --region eu-west-1 2>&1; then
        error_exit "Failed to create user"
    fi
    
    log_success "User created: ${email}"
}

# Add to Admins group
add_to_admins() {
    local pool_id="$1"
    local email="$2"
    
    log_info "Adding user to Admins group"
    
    aws cognito-idp admin-add-user-to-group \
        --user-pool-id "${pool_id}" \
        --username "${email}" \
        --group-name Admins \
        --region eu-west-1 || error_exit "Failed to add user to Admins group"
    
    log_success "User added to Admins group"
}

# Set permanent password (optional)
set_permanent_password() {
    local pool_id="$1"
    local email="$2"
    local password="$3"
    
    if [[ -n "${password}" ]]; then
        log_info "Setting permanent password"
        
        aws cognito-idp admin-set-user-password \
            --user-pool-id "${pool_id}" \
            --username "${email}" \
            --password "${password}" \
            --permanent \
            --region eu-west-1 || error_exit "Failed to set permanent password"
        
        log_success "Permanent password set"
    fi
}

# Generate random password
generate_password() {
    # Generate password with uppercase, lowercase, numbers, and symbols
    local pass=$(openssl rand -base64 12 | head -c 12)
    echo "${pass}@Aa1!"
}

# Main function
main() {
    echo "========================================"
    log_info "Create Admin User"
    echo "========================================"
    echo ""
    
    # Get User Pool ID
    local user_pool_id
    user_pool_id=$(get_user_pool_id)
    log_info "User Pool ID: ${user_pool_id}"
    echo ""
    
    # Get email
    read -p "Enter admin email: " email
    validate_email "${email}"
    echo ""
    
    # Generate or get password
    local temp_password
    read -p "Generate random temporary password? (y/n): " gen_pass
    if [[ "${gen_pass}" =~ ^[Yy]$ ]]; then
        temp_password=$(generate_password)
        log_info "Generated temporary password: ${temp_password}"
    else
        read -sp "Enter temporary password: " temp_password
        echo ""
    fi
    echo ""
    
    # Optional permanent password
    local perm_password=""
    read -p "Set permanent password now? (y/n): " set_perm
    if [[ "${set_perm}" =~ ^[Yy]$ ]]; then
        read -sp "Enter permanent password: " perm_password
        echo ""
        read -sp "Confirm password: " perm_password_confirm
        echo ""
        
        if [[ "${perm_password}" != "${perm_password_confirm}" ]]; then
            error_exit "Passwords do not match"
        fi
    fi
    echo ""
    
    # Confirm
    log_info "Summary:"
    echo "  Email: ${email}"
    echo "  User Pool: ${user_pool_id}"
    echo "  Group: Admins"
    echo ""
    read -p "Create admin user? (y/n): " confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        exit 0
    fi
    echo ""
    
    # Create user
    create_user "${user_pool_id}" "${email}" "${temp_password}"
    
    # Add to Admins group
    add_to_admins "${user_pool_id}" "${email}"
    
    # Set permanent password if provided
    if [[ -n "${perm_password}" ]]; then
        set_permanent_password "${user_pool_id}" "${email}" "${perm_password}"
    fi
    
    echo ""
    echo "========================================"
    log_success "Admin user created successfully!"
    echo "========================================"
    echo ""
    log_info "Login credentials:"
    echo "  Email: ${email}"
    if [[ -n "${perm_password}" ]]; then
        echo "  Password: (permanent password set)"
    else
        echo "  Temporary Password: ${temp_password}"
        echo "  (User will be prompted to change on first login)"
    fi
    echo ""
}

# Run main
main "$@"
