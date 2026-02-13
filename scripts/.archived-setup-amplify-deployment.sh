#!/bin/bash
# Setup Amplify Frontend Deployment via Terraform
# This script helps configure and deploy the frontend to AWS Amplify
#
# IMPORTANT: GitHub token is managed externally via create-github-secret.sh
# This ensures the token never appears in Terraform files or state

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
TFVARS_FILE="${TERRAFORM_DIR}/terraform.tfvars"
DEFAULT_SECRET_NAME="task-manager-github-token"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Check if GitHub secret exists in Secrets Manager
check_github_secret() {
    local secret_name="$1"
    log_info "Checking for GitHub token secret: $secret_name"

    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "${AWS_REGION:-eu-west-1}" &>/dev/null; then
        log_success "✓ GitHub token secret found"
        return 0
    else
        log_error "✗ GitHub token secret not found"
        return 1
    fi
}

# Prompt for GitHub repository URL
prompt_repository() {
    log_info "Enter your GitHub repository URL"
    log_info "Example: https://github.com/username/aws-serverless-task-manager"
    read -p "Repository URL: " REPO_URL

    if [[ ! "$REPO_URL" =~ ^https://github\.com/.+/.+ ]]; then
        die "Invalid GitHub repository URL format"
    fi

    echo "$REPO_URL"
}

# Update terraform.tfvars file
update_tfvars() {
    local repo_url="$1"
    local secret_name="$2"
    local main_branch="${3:-main}"
    local dev_branch="${4:-dev}"

    log_info "Updating Terraform configuration"

    # Escape special characters for sed
    local escaped_repo_url="${repo_url//\//\\/}"

    # Update or add configuration
    if grep -q "^enable_amplify_deployment = " "$TFVARS_FILE"; then
        sed -i "s/^enable_amplify_deployment = .*/enable_amplify_deployment = true/" "$TFVARS_FILE"
        sed -i "s#^github_repository_url.*=.*#github_repository_url = \"$repo_url\"#" "$TFVARS_FILE"
        sed -i "s/^github_secret_name.*=.*/github_secret_name = \"$secret_name\"/" "$TFVARS_FILE"
        sed -i "s/^github_main_branch.*=.*/github_main_branch = \"$main_branch\"/" "$TFVARS_FILE"
        sed -i "s/^github_dev_branch.*=.*/github_dev_branch = \"$dev_branch\"/" "$TFVARS_FILE"
    else
        log_error "Configuration format not recognized. Please update terraform.tfvars manually."
        return 1
    fi

    log_success "Configuration updated"
}

# Deploy with Terraform
deploy_terraform() {
    log_info "Deploying with Terraform"
    cd "$TERRAFORM_DIR"

    log_info "Running terraform init"
    terraform init

    log_info "Running terraform plan"
    terraform plan -out=tfplan

    log_info "Review the plan above"
    read -p "Apply changes? [Y/n]: " confirm

    if [[ ! "$confirm" =~ ^[Nn] ]]; then
        log_info "Applying Terraform changes"
        terraform apply tfplan
        rm -f tfplan

        log_success "Deployment complete!"

        # Show outputs
        echo ""
        log_info "Frontend URLs:"
        terraform output amplify_main_branch_url 2>/dev/null || echo "  (not yet available)"
        terraform output amplify_dev_branch_url 2>/dev/null || echo ""
    else
        log_info "Deployment cancelled"
        rm -f tfplan
    fi
}

# Show current configuration
show_config() {
    log_info "Current Amplify Configuration"
    echo ""

    if grep -q "^enable_amplify_deployment = true" "$TFVARS_FILE" 2>/dev/null; then
        grep "^enable_amplify_deployment" "$TFVARS_FILE" || true
        grep "^github_repository_url" "$TFVARS_FILE" || true
        grep "^github_secret_name" "$TFVARS_FILE" || true
        grep "^github_main_branch" "$TFVARS_FILE" || true
        grep "^github_dev_branch" "$TFVARS_FILE" || true
        echo ""

        # Check if deployed
        cd "$TERRAFORM_DIR"
        if terraform output amplify_app_id &>/dev/null; then
            log_success "Amplify app is deployed"
            echo "App ID: $(terraform output -raw amplify_app_id)"
            echo "Main URL: $(terraform output -raw amplify_main_branch_url)"
        else
            log_warn "Amplify configured but not yet deployed"
        fi
    else
        log_warn "Amplify deployment not enabled in terraform.tfvars"
    fi
}

# Rotate GitHub token
rotate_token() {
    log_info "To rotate the GitHub token, run:"
    echo ""
    echo "  ./scripts/create-github-secret.sh"
    echo ""
    log_info "The secret in AWS Secrets Manager will be updated automatically."
    log_info "No Terraform changes needed - Amplify will use the new token immediately."
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo "═══════════════════════════════════════════════════════════"
    log_info "AWS Amplify Frontend Deployment Setup"
    echo "═══════════════════════════════════════════════════════════"
    echo ""

    # Check AWS credentials
    check_aws_auth

    echo ""

    # Check if already configured
    if grep -q "^enable_amplify_deployment = true" "$TFVARS_FILE" 2>/dev/null; then
        log_info "Amplify is already enabled"
        show_config
        echo ""

        PS3="Select an option: "
        options=("Show current config" "Re-deploy" "Rotate GitHub token" "Exit")
        select opt in "${options[@]}"; do
            case $opt in
                "Show current config")
                    show_config
                    ;;
                "Re-deploy")
                    deploy_terraform
                    break
                    ;;
                "Rotate GitHub token")
                    rotate_token
                    break
                    ;;
                "Exit")
                    exit 0
                    ;;
                *)
                    log_error "Invalid option"
                    ;;
            esac
        done
    else
        # Initial setup
        log_info "Setting up Amplify deployment for the first time"
        echo ""

        # Check for GitHub secret first
        read -p "GitHub secret name [$DEFAULT_SECRET_NAME]: " SECRET_NAME
        SECRET_NAME="${SECRET_NAME:-$DEFAULT_SECRET_NAME}"

        if ! check_github_secret "$SECRET_NAME"; then
            echo ""
            log_error "GitHub token secret not found in AWS Secrets Manager"
            log_info "Please create it first by running:"
            echo ""
            echo "  ./scripts/create-github-secret.sh"
            echo ""
            log_info "Then run this script again."
            exit 1
        fi

        echo ""

        # Get configuration
        REPO_URL=$(prompt_repository)

        log_info "Enter branch names (or press Enter for defaults)"
        read -p "Main branch [main]: " MAIN_BRANCH
        MAIN_BRANCH=${MAIN_BRANCH:-main}

        read -p "Dev branch [dev]: " DEV_BRANCH
        DEV_BRANCH=${DEV_BRANCH:-dev}

        # Update configuration
        update_tfvars "$REPO_URL" "$SECRET_NAME" "$MAIN_BRANCH" "$DEV_BRANCH"

        # Deploy
        echo ""
        deploy_terraform

        echo ""
        log_success "═══════════════════════════════════════════════════════════"
        log_success "Setup Complete!"
        log_success "═══════════════════════────────────────────────────────════"
        echo ""
        log_info "Your frontend is now deployed to AWS Amplify"
        log_info "To rotate the GitHub token later, run: ./scripts/create-github-secret.sh"
        echo ""
    fi
}

main "$@"
