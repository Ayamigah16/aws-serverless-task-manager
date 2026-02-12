#!/bin/bash
# SES Email Verification Script
# Verifies an email address for use with Amazon SES

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Verify email with SES
verify_ses_email() {
    local email="$1"

    log_info "Sending verification email to: ${email}"

    aws ses verify-email-identity \
        --email-address "${email}" \
        --region "${AWS_REGION}" \
        --no-cli-pager || die "Failed to verify email"

    log_success "Verification email sent"
}

# Check verification status
check_verification_status() {
    local email="$1"

    log_info "Checking verification status"

    local status
    status=$(aws ses get-identity-verification-attributes \
        --identities "${email}" \
        --region "${AWS_REGION}" \
        --query "VerificationAttributes.\"${email}\".VerificationStatus" \
        --output text 2>/dev/null) || status="Unknown"

    echo "${status}"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "SES Email Verification"
    echo ""

    # Check prerequisites
    require_commands aws
    check_aws_auth

    # Get email address
    local email
    email=$(prompt_input "Enter email address to verify" validate_email)
    echo ""

    # Check current status
    local current_status
    current_status=$(check_verification_status "${email}")

    if [ "${current_status}" = "Success" ]; then
        log_success "Email already verified: ${email}"
        exit 0
    fi

    # Verify email
    verify_ses_email "${email}"

    echo ""
    log_success "Verification initiated"
    echo ""
    log_info "Check your inbox and click the verification link"
    echo ""
    echo "To check status:"
    echo "  aws ses get-identity-verification-attributes --identities ${email} --region ${AWS_REGION}"
}

main "$@"
