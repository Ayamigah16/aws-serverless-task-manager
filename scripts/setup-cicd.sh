#!/bin/bash
# CI/CD Setup Script
# This script helps configure GitHub Actions CI/CD for the AWS Serverless Task Manager

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Display banner
show_banner() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║     AWS Serverless Task Manager - CI/CD Setup            ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Get AWS account information
get_aws_info() {
    log_info "Gathering AWS account information..."

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
    if [ -z "$AWS_ACCOUNT_ID" ]; then
        log_error "Unable to get AWS account ID. Is AWS CLI configured?"
        exit 1
    fi

    AWS_REGION=$(aws configure get region || echo "eu-west-1")

    log_info "AWS Account ID: $AWS_ACCOUNT_ID"
    log_info "AWS Region: $AWS_REGION"
}

setup_oidc_provider() {
    log_info "Setting up GitHub OIDC provider..."

    # Check if provider exists
    PROVIDER_ARN=$(aws iam list-open-id-connect-providers \
        --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" \
        --output text 2>/dev/null || true)

    if [ -z "$PROVIDER_ARN" ]; then
        log_info "Creating OIDC provider..."
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --client-id-list sts.amazonaws.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null

        PROVIDER_ARN=$(aws iam list-open-id-connect-providers \
            --query "OpenIDConnectProviderList[?ends_with(Arn, 'token.actions.githubusercontent.com')].Arn" \
            --output text)

        log_info "OIDC provider created ✓"
    else
        log_info "OIDC provider already exists ✓"
    fi

    echo "$PROVIDER_ARN"
}

create_iam_role() {
    local github_repo=$1
    log_info "Creating IAM role for GitHub Actions..."

    # Create trust policy
    cat > /tmp/github-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${github_repo}:*"
        }
      }
    }
  ]
}
EOF

    # Check if role exists
    ROLE_ARN=$(aws iam get-role --role-name GitHubActionsDeploymentRole \
        --query 'Role.Arn' --output text 2>/dev/null || true)

    if [ -z "$ROLE_ARN" ]; then
        log_info "Creating IAM role..."
        aws iam create-role \
            --role-name GitHubActionsDeploymentRole \
            --assume-role-policy-document file:///tmp/github-trust-policy.json \
            --description "Role for GitHub Actions CI/CD" >/dev/null

        log_info "Attaching policies..."
        aws iam attach-role-policy \
            --role-name GitHubActionsDeploymentRole \
            --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

        ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/GitHubActionsDeploymentRole"
        log_info "IAM role created ✓"
    else
        log_info "IAM role already exists ✓"
    fi

    rm -f /tmp/github-trust-policy.json
    echo "$ROLE_ARN"
}

setup_terraform_backend() {
    log_info "Setting up Terraform backend..."

    local bucket_name="task-manager-terraform-state-${AWS_REGION}"
    local table_name="task-manager-terraform-locks"

    # Create S3 bucket
    if ! aws s3 ls "s3://${bucket_name}" 2>/dev/null; then
        log_info "Creating S3 bucket for Terraform state..."
        if [ "$AWS_REGION" = "us-east-1" ]; then
            aws s3 mb "s3://${bucket_name}"
        else
            aws s3 mb "s3://${bucket_name}" --region "$AWS_REGION"
        fi

        aws s3api put-bucket-versioning \
            --bucket "${bucket_name}" \
            --versioning-configuration Status=Enabled

        aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'

        log_info "S3 bucket created ✓"
    else
        log_info "S3 bucket already exists ✓"
    fi

    # Create DynamoDB table
    if ! aws dynamodb describe-table --table-name "$table_name" >/dev/null 2>&1; then
        log_info "Creating DynamoDB table for state locking..."
        aws dynamodb create-table \
            --table-name "$table_name" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$AWS_REGION" >/dev/null

        log_info "Waiting for table to be active..."
        aws dynamodb wait table-exists --table-name "$table_name"
        log_info "DynamoDB table created ✓"
    else
        log_info "DynamoDB table already exists ✓"
    fi

    echo "$bucket_name|$table_name"
}

configure_github_secrets() {
    local role_arn=$1
    local bucket_name=$2
    local table_name=$3

    log_info "Configuring GitHub secrets..."

    if command -v gh >/dev/null 2>&1; then
        prompt "Do you want to set GitHub secrets automatically? (y/n): "
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
            log_info "Setting repository secrets..."

            gh secret set AWS_ROLE_ARN --body "$role_arn"
            gh secret set TF_STATE_BUCKET --body "$bucket_name"
            gh secret set TF_STATE_LOCK_TABLE --body "$table_name"
            gh secret set AWS_REGION --body "$AWS_REGION"

            log_info "GitHub secrets configured ✓"
            return
        fi
    fi

    # Manual instructions
    echo ""
    log_warn "Please set the following secrets manually in GitHub:"
    echo ""
    echo -e "${BLUE}Repository Secrets (Settings → Secrets and variables → Actions):${NC}"
    echo ""
    echo "AWS_ROLE_ARN = $role_arn"
    echo "TF_STATE_BUCKET = $bucket_name"
    echo "TF_STATE_LOCK_TABLE = $table_name"
    echo "AWS_REGION = $AWS_REGION"
    echo ""
}

create_environments() {
    log_info "Setting up GitHub environments..."

    if command -v gh >/dev/null 2>&1; then
        log_info "Creating environments: sandbox, staging, production"

        for env in sandbox staging production; do
            gh api -X PUT "repos/:owner/:repo/environments/$env" \
                --silent 2>/dev/null || true
        done

        log_info "Environments created ✓"
    else
        log_warn "Please create environments manually in GitHub:"
        echo "  Settings → Environments → New environment"
        echo "  Create: sandbox, staging, production"
    fi
}

print_summary() {
    local role_arn=$1
    local bucket_name=$2
    local table_name=$3

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              CI/CD Setup Complete! ✓                     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Configuration Summary:${NC}"
    echo ""
    echo "AWS Account ID: $AWS_ACCOUNT_ID"
    echo "AWS Region: $AWS_REGION"
    echo "IAM Role ARN: $role_arn"
    echo "Terraform State Bucket: $bucket_name"
    echo "Terraform Lock Table: $table_name"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo ""
    echo "1. Verify GitHub secrets are set:"
    echo "   gh secret list"
    echo ""
    echo "2. Review and update environment-specific configs:"
    echo "   terraform/environments/sandbox.tfvars"
    echo "   terraform/environments/staging.tfvars"
    echo "   terraform/environments/production.tfvars"
    echo ""
    echo "3. Deploy infrastructure:"
    echo "   cd terraform"
    echo "   terraform init"
    echo "   terraform apply -var-file=environments/sandbox.tfvars"
    echo ""
    echo "4. Trigger first deployment via GitHub Actions:"
    echo "   gh workflow run deploy.yml -f environment=sandbox"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo "- CI/CD Guide: docs/CI_CD_GUIDE.md"
    echo "- Secrets Template: .github/SECRETS_TEMPLATE.md"
    echo ""
}

# Main execution
main() {
    # Check prerequisites
    require_commands aws jq
    check_aws_auth

    if ! command -v gh &> /dev/null; then
        log_warn "GitHub CLI (gh) not found - will show manual instructions"
    fi
    get_aws_info

    prompt "Enter your GitHub repository (format: owner/repo): "
    read -r github_repo

    if [ -z "$github_repo" ] || [[ ! "$github_repo" =~ ^[^/]+/[^/]+$ ]]; then
        log_error "Invalid repository format. Expected: owner/repo"
        exit 1
    fi

    log_info "Setting up CI/CD for: $github_repo"
    echo ""

    oidc_provider=$(setup_oidc_provider)
    role_arn=$(create_iam_role "$github_repo")
    backend_info=$(setup_terraform_backend)

    IFS='|' read -r bucket_name table_name <<< "$backend_info"

    configure_github_secrets "$role_arn" "$bucket_name" "$table_name"
    create_environments
    print_summary "$role_arn" "$bucket_name" "$table_name"
}

# Run main function
main "$@"
