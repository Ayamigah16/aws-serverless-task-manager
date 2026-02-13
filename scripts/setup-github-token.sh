#!/bin/bash
# Helper script to store GitHub token in AWS Secrets Manager
# This can be run before Terraform if you want to manually create the secret

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
die() { log_error "$1"; exit 1; }

# ============================================================================
# MAIN
# ============================================================================

echo "========================================="
echo "GitHub Token Setup for AWS Secrets Manager"
echo "========================================="
echo ""

# Get environment
read -p "Environment (sandbox/staging/production): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-sandbox}

# Secret name
SECRET_NAME="task-manager-${ENVIRONMENT}-github-token"

log_info "This script will store your GitHub Personal Access Token in AWS Secrets Manager"
log_info "Secret name: ${SECRET_NAME}"
echo ""

# Check if secret already exists
if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" &>/dev/null; then
    log_warn "Secret '${SECRET_NAME}' already exists!"
    read -p "Do you want to update it? [y/N]: " UPDATE
    if [[ ! "$UPDATE" =~ ^[Yy]$ ]]; then
        log_info "Exiting without changes"
        exit 0
    fi
    UPDATE_MODE=true
else
    UPDATE_MODE=false
fi

echo ""
echo "========================================="
echo "GitHub Token Requirements"
echo "========================================="
echo "1. Go to: https://github.com/settings/tokens"
echo "2. Click 'Generate new token (classic)'"
echo "3. Required scopes:"
echo "   - repo (Full control of private repositories)"
echo "4. Copy the token (you'll only see it once!)"
echo ""

# Get token from user
read -sp "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    die "Token cannot be empty"
fi

# Validate token format
if [[ ! "$GITHUB_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] && [[ ! "$GITHUB_TOKEN" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
    log_warn "Token format doesn't match expected pattern"
    log_warn "Classic tokens start with 'ghp_', fine-grained tokens start with 'github_pat_'"
    read -p "Continue anyway? [y/N]: " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        die "Cancelled by user"
    fi
fi

echo ""
log_info "Storing token in AWS Secrets Manager..."

# Store or update the secret
if [ "$UPDATE_MODE" = true ]; then
    aws secretsmanager update-secret \
        --secret-id "${SECRET_NAME}" \
        --secret-string "${GITHUB_TOKEN}" \
        > /dev/null

    log_info "✓ Secret updated successfully"
else
    aws secretsmanager create-secret \
        --name "${SECRET_NAME}" \
        --description "GitHub Personal Access Token for Amplify deployments - ${ENVIRONMENT}" \
        --secret-string "${GITHUB_TOKEN}" \
        --tags Key=Environment,Value="${ENVIRONMENT}" \
               Key=Purpose,Value="Amplify Git Integration" \
               Key=ManagedBy,Value="Manual" \
        > /dev/null

    log_info "✓ Secret created successfully"
fi

echo ""
echo "========================================="
echo "✓ Setup Complete!"
echo "========================================="
echo ""
echo "Secret ARN:"
aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --query 'ARN' --output text
echo ""
echo "Next steps:"
echo "1. Update terraform/terraform.tfvars:"
echo "   enable_amplify_deployment = true"
echo "   create_github_token_secret = false"
echo "   existing_github_secret_name = \"${SECRET_NAME}\""
echo ""
echo "2. Run terraform:"
echo "   cd terraform"
echo "   terraform plan"
echo "   terraform apply"
echo ""
log_info "Your GitHub token is now securely stored in AWS Secrets Manager"
