#!/bin/bash
# Deploy SNS Notification System
# Deploys SNS infrastructure via Terraform

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Deploy Terraform changes
deploy_terraform() {
    log_info "Applying Terraform changes for SNS"

    cd "${PROJECT_ROOT}/terraform" || die "Terraform directory not found"

    terraform apply -auto-approve || die "Terraform apply failed"

    log_success "Infrastructure deployed"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Deploy SNS Notification System"

    # Check prerequisites
    require_commands aws terraform
    check_aws_auth

    # Deploy infrastructure (includes notification-handler Lambda)
    log_info "Terraform will deploy:"
    log_info "  • SNS topic and subscriptions"
    log_info "  • notification-handler Lambda function"
    log_info "  • EventBridge rules for notifications"

    deploy_terraform

    # Get SNS topic ARN
    local sns_topic_arn
    sns_topic_arn=$(get_terraform_output "sns_topic_arn") || die "Failed to get SNS topic ARN"
    log_info "SNS Topic: ${sns_topic_arn}"

    log_success "SNS deployment complete"
    log_warn "Check your email to confirm SNS subscriptions"
    log_info "AWS sends confirmation emails to addresses in notification_emails"
}

main "$@"

