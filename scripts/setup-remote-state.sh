#!/bin/bash

# Terraform Remote State Setup Script
# Sets up S3 bucket and DynamoDB table for Terraform state management

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly AWS_REGION="${AWS_REGION:-eu-west-1}"
readonly BUCKET_NAME="task-manager-terraform-state-${AWS_REGION}"
readonly TABLE_NAME="task-manager-terraform-locks"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

# Error handler
error_exit() {
    log_error "$1"
    exit "${2:-1}"
}

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error_exit "AWS CLI is not installed. Please install it first."
    fi
    log_success "AWS CLI found"
}

# Check AWS credentials
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        error_exit "AWS credentials not configured. Run 'aws configure' first."
    fi
    log_success "AWS credentials validated"
}

# Get AWS account ID
get_account_id() {
    local account_id
    account_id=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || 
        error_exit "Failed to get AWS account ID"
    echo "${account_id}"
}

# Check if S3 bucket exists
bucket_exists() {
    aws s3api head-bucket --bucket "$1" 2>/dev/null
}

# Create S3 bucket
create_s3_bucket() {
    local bucket="$1"
    local region="$2"
    
    log_info "Checking S3 bucket: ${bucket}"
    
    if bucket_exists "${bucket}"; then
        log_warn "Bucket already exists: ${bucket}"
        return 0
    fi
    
    log_info "Creating S3 bucket: ${bucket}"
    
    if [[ "${region}" == "us-east-1" ]]; then
        aws s3api create-bucket \
            --bucket "${bucket}" \
            --region "${region}" 2>/dev/null || {
            log_error "Failed to create bucket: ${bucket}"
            return 1
        }
    else
        aws s3api create-bucket \
            --bucket "${bucket}" \
            --region "${region}" \
            --create-bucket-configuration LocationConstraint="${region}" 2>/dev/null || {
            log_error "Failed to create bucket: ${bucket}"
            return 1
        }
    fi
    
    log_success "Bucket created: ${bucket}"
}

# Enable bucket versioning
enable_bucket_versioning() {
    local bucket="$1"
    
    log_info "Enabling versioning on bucket: ${bucket}"
    
    if aws s3api put-bucket-versioning \
        --bucket "${bucket}" \
        --versioning-configuration Status=Enabled 2>/dev/null; then
        log_success "Versioning enabled"
    else
        log_warn "Failed to enable versioning (may already be enabled or insufficient permissions)"
    fi
}

# Enable bucket encryption
enable_bucket_encryption() {
    local bucket="$1"
    
    log_info "Enabling encryption on bucket: ${bucket}"
    
    if aws s3api put-bucket-encryption \
        --bucket "${bucket}" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }]
        }' 2>/dev/null; then
        log_success "Encryption enabled"
    else
        log_warn "Failed to enable encryption (may already be enabled or insufficient permissions)"
    fi
}

# Block public access
block_public_access() {
    local bucket="$1"
    
    log_info "Blocking public access on bucket: ${bucket}"
    
    if aws s3api put-public-access-block \
        --bucket "${bucket}" \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" 2>/dev/null; then
        log_success "Public access blocked"
    else
        log_warn "Failed to block public access (may already be configured or insufficient permissions)"
    fi
}

# Check if DynamoDB table exists
table_exists() {
    aws dynamodb describe-table --table-name "$1" --region "$2" &> /dev/null
}

# Create DynamoDB table
create_dynamodb_table() {
    local table="$1"
    local region="$2"
    
    log_info "Checking DynamoDB table: ${table}"
    
    if table_exists "${table}" "${region}"; then
        log_warn "Table already exists: ${table}"
        return 0
    fi
    
    log_info "Creating DynamoDB table: ${table}"
    
    if aws dynamodb create-table \
        --table-name "${table}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${region}" \
        --tags Key=Project,Value=task-manager Key=ManagedBy,Value=script &> /dev/null; then
        
        log_info "Waiting for table to be active..."
        aws dynamodb wait table-exists --table-name "${table}" --region "${region}" || {
            log_error "Table creation timeout"
            return 1
        }
        log_success "Table created: ${table}"
    else
        log_error "Failed to create table: ${table}"
        return 1
    fi
}

# Main function
main() {
    log_info "Starting Terraform Remote State Setup"
    echo "========================================"
    
    # Pre-flight checks
    check_aws_cli
    check_aws_credentials
    
    local account_id
    account_id=$(get_account_id)
    
    echo ""
    log_info "Configuration:"
    echo "  AWS Region:     ${AWS_REGION}"
    echo "  Account ID:     ${account_id}"
    echo "  S3 Bucket:      ${BUCKET_NAME}"
    echo "  DynamoDB Table: ${TABLE_NAME}"
    echo "========================================"
    echo ""
    
    # Create and configure S3 bucket
    create_s3_bucket "${BUCKET_NAME}" "${AWS_REGION}" || error_exit "S3 bucket setup failed"
    enable_bucket_versioning "${BUCKET_NAME}"
    enable_bucket_encryption "${BUCKET_NAME}"
    block_public_access "${BUCKET_NAME}"
    
    echo ""
    
    # Create DynamoDB table
    create_dynamodb_table "${TABLE_NAME}" "${AWS_REGION}" || error_exit "DynamoDB table setup failed"
    
    echo ""
    echo "========================================"
    log_success "Remote state setup complete!"
    echo "========================================"
    echo ""
    log_info "Next steps:"
    echo "  1. cd terraform"
    echo "  2. terraform init"
    echo "  3. terraform plan"
    echo "  4. terraform apply"
    echo ""
}

# Run main function
main "$@"
