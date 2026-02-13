#!/bin/bash
# Update Amplify Environment Variables from Terraform Outputs
# This script fetches infrastructure outputs from Terraform and configures Amplify

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
readonly TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Update AWS Amplify app environment variables from Terraform outputs.

OPTIONS:
    -e, --environment ENV    Environment name (sandbox/staging/production) [required]
    -a, --app-id APP_ID      Amplify App ID (auto-detected if not provided)
    -r, --region REGION      AWS Region (default: eu-west-1)
    -h, --help               Show this help message

EXAMPLES:
    # Update sandbox environment (auto-detect app ID)
    $(basename "$0") -e sandbox

    # Update staging with specific app ID
    $(basename "$0") -e staging -a d1234567890abc

    # Update production in different region
    $(basename "$0") -e production -r us-east-1

REQUIREMENTS:
    - AWS CLI configured with appropriate credentials
    - Terraform state accessible
    - Amplify app already created

EOF
    exit 1
}

# Get Terraform outputs
get_terraform_outputs() {
    local environment=$1

    log_info "Fetching Terraform outputs for environment: ${environment}"

    cd "${TERRAFORM_DIR}" || exit 1

    # Check if Terraform is initialized
    if [ ! -d ".terraform" ]; then
        log_warn "Terraform not initialized. Initializing now..."
        terraform init -backend-config="key=${environment}/terraform.tfstate" >/dev/null
    fi

    # Get outputs
    if ! terraform output -json > /tmp/terraform-outputs.json 2>/dev/null; then
        log_error "Failed to get Terraform outputs"
        log_error "Make sure infrastructure is deployed for environment: ${environment}"
        exit 1
    fi

    log_success "Terraform outputs retrieved"
    cd - >/dev/null
}

# Parse Terraform output value
get_output_value() {
    local key=$1
    local value

    value=$(jq -r ".${key}.value // empty" /tmp/terraform-outputs.json 2>/dev/null)

    if [ -z "$value" ] || [ "$value" = "null" ]; then
        echo ""
    else
        echo "$value"
    fi
}

# Find Amplify App ID
find_amplify_app_id() {
    local environment=$1
    local region=$2
    local app_name="task-manager-${environment}"

    log_info "Looking for Amplify app: ${app_name}"

    local app_id
    app_id=$(aws amplify list-apps \
        --region "${region}" \
        --query "apps[?name=='${app_name}'].appId" \
        --output text 2>/dev/null || echo "")

    if [ -z "$app_id" ]; then
        log_error "Amplify app not found: ${app_name}"
        log_error "Please create the Amplify app first or provide --app-id"
        log_info "You can create it with: aws amplify create-app --name ${app_name}"
        exit 1
    fi

    log_success "Found Amplify app: ${app_id}"
    echo "$app_id"
}

# Update Amplify environment variables
update_amplify_env() {
    local app_id=$1
    local region=$2
    local environment=$3

    log_info "Parsing Terraform outputs..."

    # Get values from Terraform outputs
    local api_url
    local cognito_pool_id
    local cognito_client_id
    local appsync_url
    local s3_bucket

    api_url=$(get_output_value "api_url")
    cognito_pool_id=$(get_output_value "cognito_user_pool_id")
    cognito_client_id=$(get_output_value "cognito_client_id")
    appsync_url=$(get_output_value "appsync_graphql_url")
    s3_bucket=$(get_output_value "s3_bucket_name")

    # Validate required values
    if [ -z "$api_url" ]; then
        log_error "API URL not found in Terraform outputs"
        exit 1
    fi

    if [ -z "$cognito_pool_id" ]; then
        log_error "Cognito User Pool ID not found in Terraform outputs"
        exit 1
    fi

    if [ -z "$cognito_client_id" ]; then
        log_error "Cognito Client ID not found in Terraform outputs"
        exit 1
    fi

    log_info "Building environment variables..."

    # Build environment variables JSON
    local env_vars='{'
    env_vars+="\"NEXT_PUBLIC_AWS_REGION\":\"${region}\","
    env_vars+="\"NEXT_PUBLIC_API_URL\":\"${api_url}\","
    env_vars+="\"NEXT_PUBLIC_COGNITO_USER_POOL_ID\":\"${cognito_pool_id}\","
    env_vars+="\"NEXT_PUBLIC_COGNITO_CLIENT_ID\":\"${cognito_client_id}\","
    env_vars+="\"NEXT_PUBLIC_ENVIRONMENT\":\"${environment}\""

    # Add optional values if they exist
    if [ -n "$appsync_url" ]; then
        env_vars+=",\"NEXT_PUBLIC_APPSYNC_URL\":\"${appsync_url}\""
    fi

    if [ -n "$s3_bucket" ]; then
        env_vars+=",\"NEXT_PUBLIC_S3_BUCKET\":\"${s3_bucket}\""
    fi

    env_vars+='}'

    log_info "Updating Amplify app environment variables..."

    # Update Amplify app
    if aws amplify update-app \
        --app-id "${app_id}" \
        --region "${region}" \
        --environment-variables "${env_vars}" \
        --output json > /tmp/amplify-update.json; then

        log_success "Environment variables updated successfully"

        # Display configured variables
        echo ""
        log_info "Configured environment variables:"
        echo "  NEXT_PUBLIC_AWS_REGION = ${region}"
        echo "  NEXT_PUBLIC_API_URL = ${api_url}"
        echo "  NEXT_PUBLIC_COGNITO_USER_POOL_ID = ${cognito_pool_id}"
        echo "  NEXT_PUBLIC_COGNITO_CLIENT_ID = ${cognito_client_id}"
        echo "  NEXT_PUBLIC_ENVIRONMENT = ${environment}"

        if [ -n "$appsync_url" ]; then
            echo "  NEXT_PUBLIC_APPSYNC_URL = ${appsync_url}"
        fi

        if [ -n "$s3_bucket" ]; then
            echo "  NEXT_PUBLIC_S3_BUCKET = ${s3_bucket}"
        fi

        echo ""
    else
        log_error "Failed to update Amplify app"
        exit 1
    fi
}

# Trigger new build (optional)
trigger_build() {
    local app_id=$1
    local region=$2
    local branch=$3

    log_info "Do you want to trigger a new build? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Triggering build for branch: ${branch}"

        local job_id
        job_id=$(aws amplify start-job \
            --app-id "${app_id}" \
            --branch-name "${branch}" \
            --job-type RELEASE \
            --region "${region}" \
            --query 'jobSummary.jobId' \
            --output text 2>/dev/null || echo "")

        if [ -n "$job_id" ]; then
            log_success "Build triggered: ${job_id}"
            log_info "Monitor build at: https://${region}.console.aws.amazon.com/amplify/home?region=${region}#/${app_id}/${branch}/${job_id}"
        else
            log_warn "Failed to trigger build. You can manually trigger it from Amplify Console."
        fi
    fi
}

# Cleanup
cleanup() {
    rm -f /tmp/terraform-outputs.json /tmp/amplify-update.json
}

# Main function
main() {
    local environment=""
    local app_id=""
    local region="${AWS_REGION:-eu-west-1}"
    local branch="main"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            -a|--app-id)
                app_id="$2"
                shift 2
                ;;
            -r|--region)
                region="$2"
                shift 2
                ;;
            -b|--branch)
                branch="$2"
                shift 2
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$environment" ]; then
        log_error "Environment is required"
        usage
    fi

    # Validate environment value
    if [[ ! "$environment" =~ ^(sandbox|staging|production)$ ]]; then
        log_error "Invalid environment: ${environment}"
        log_error "Must be one of: sandbox, staging, production"
        exit 1
    fi

    # Set branch based on environment if not specified
    case "$environment" in
        sandbox)
            branch="${branch:-develop}"
            ;;
        staging)
            branch="${branch:-develop}"
            ;;
        production)
            branch="${branch:-main}"
            ;;
    esac

    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║        Update Amplify Environment Variables              ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    echo "Environment: ${environment}"
    echo "Region: ${region}"
    echo "Branch: ${branch}"
    echo ""

    # Check prerequisites
    # Check prerequisites
    require_commands aws jq terraform
    check_aws_auth

    # Get Terraform outputs
    get_terraform_outputs "${environment}"

    # Find or use provided Amplify App ID
    if [ -z "$app_id" ]; then
        app_id=$(find_amplify_app_id "${environment}" "${region}")
    else
        log_info "Using provided Amplify App ID: ${app_id}"
    fi

    # Update Amplify environment variables
    update_amplify_env "${app_id}" "${region}" "${environment}"

    # Optionally trigger new build
    trigger_build "${app_id}" "${region}" "${branch}"

    # Cleanup
    cleanup

    echo ""
    log_success "All done! ✨"
    echo ""
    log_info "Next steps:"
    echo "  1. Verify settings in Amplify Console"
    echo "  2. Trigger a deployment if not done automatically"
    echo "  3. Test the deployed application"
    echo ""
}

# Trap cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
