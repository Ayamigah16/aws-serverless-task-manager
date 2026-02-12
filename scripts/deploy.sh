#!/bin/bash
# Automated Full Stack Deployment
# Orchestrates complete deployment: Infrastructure (via Terraform) -> Frontend

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

readonly TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
readonly FRONTEND_DIR="${PROJECT_ROOT}/frontend"

# Deployment components
DEPLOY_INFRASTRUCTURE="${DEPLOY_INFRASTRUCTURE:-true}"
DEPLOY_FRONTEND="${DEPLOY_FRONTEND:-true}"
SKIP_BUILD="${SKIP_BUILD:-false}"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Display deployment plan
show_deployment_plan() {
    log_info "Deployment Plan"
    echo ""
    echo "Environment:    ${ENVIRONMENT}"
    echo "AWS Region:     ${AWS_REGION}"
    echo ""
    echo "Components:"
    [ "${DEPLOY_INFRASTRUCTURE}" = "true" ] && echo "  ✓ Infrastructure & Lambda Functions (Terraform)" || echo "  ✗ Infrastructure"
    [ "${DEPLOY_FRONTEND}" = "true" ] && echo "  ✓ Frontend (Amplify)" || echo "  ✗ Frontend"
    [ "${SKIP_BUILD}" = "true" ] && echo "  ⚠ Skipping Lambda build (using existing ZIPs)"
    echo ""
}

# Deploy infrastructure and Lambda functions with Terraform
deploy_infrastructure() {
    log_info "Deploying Infrastructure & Lambda Functions"

    require_directory "${TERRAFORM_DIR}" "Terraform directory"
    cd "${TERRAFORM_DIR}"

    # Build Lambda functions first if not skipped
    # Note: Terraform will also trigger build via null_resource, but building
    # first ensures ZIPs exist before Terraform accesses them
    if [ "${SKIP_BUILD}" != "true" ]; then
        log_info "Pre-building Lambda functions"
        "${SCRIPT_DIR}/build-lambdas.sh" || die "Lambda build failed"
    fi

    # Initialize Terraform
    log_info "Initializing Terraform"
    terraform init -upgrade || die "Terraform init failed"

    # Validate configuration
    log_info "Validating Terraform configuration"
    terraform validate || die "Terraform validation failed"

    # Plan deployment
    log_info "Planning infrastructure changes"
    terraform plan -out=tfplan || die "Terraform plan failed"

    # Apply changes
    log_info "Applying infrastructure changes"
    log_info "Terraform will automatically:"
    log_info "  • Build Lambda functions (if source code changed)"
    log_info "  • Deploy all Lambda functions and layers"
    log_info "  • Update infrastructure resources"
    terraform apply tfplan || die "Terraform apply failed"

    # Cleanup plan file
    rm -f tfplan

    log_success "Infrastructure & Lambda functions deployed"
}

# Deploy frontend configuration
deploy_frontend() {
    log_info "Deploying Frontend Configuration"

    require_directory "${FRONTEND_DIR}" "Frontend directory"
    cd "${FRONTEND_DIR}"

    # Get infrastructure outputs for frontend config
    log_info "Retrieving infrastructure outputs"

    local cognito_pool_id cognito_client_id appsync_url aws_region
    cognito_pool_id=$(get_terraform_output "cognito_user_pool_id") || die "Failed to get Cognito Pool ID"
    cognito_client_id=$(get_terraform_output "cognito_user_pool_client_id") || die "Failed to get Cognito Client ID"
    appsync_url=$(get_terraform_output "appsync_graphql_url") || die "Failed to get AppSync URL"
    aws_region="${AWS_REGION}"

    # Create frontend config
    log_info "Creating frontend configuration"
    cat > "${FRONTEND_DIR}/.env.production" << EOF
NEXT_PUBLIC_API_URL=${appsync_url}
NEXT_PUBLIC_COGNITO_USER_POOL_ID=${cognito_pool_id}
NEXT_PUBLIC_COGNITO_USER_POOL_CLIENT_ID=${cognito_client_id}
NEXT_PUBLIC_APPSYNC_URL=${appsync_url}
NEXT_PUBLIC_AWS_REGION=${aws_region}
EOF

    log_success "Frontend configuration created"
    log_info "Amplify will automatically rebuild on next push"
}

# Run basic smoke tests
run_smoke_tests() {
    log_info "Running smoke tests"

    # Test AppSync endpoint
    local appsync_url
    appsync_url=$(get_terraform_output "appsync_graphql_url" 2>/dev/null)

    if [ -n "${appsync_url}" ]; then
        log_info "AppSync endpoint configured: ${appsync_url}"
        log_success "AppSync is deployed"
    fi

    log_success "Smoke tests completed"
}

# Show deployment summary
show_deployment_summary() {
    log_success "Deployment Summary"
    echo ""
    echo "Environment: ${ENVIRONMENT}"
    echo "Region:      ${AWS_REGION}"
    echo ""

    if [ "${DEPLOY_INFRASTRUCTURE}" = "true" ]; then
        echo "Infrastructure & Lambda Functions:"
        local cognito_pool_id appsync_url
        cognito_pool_id=$(get_terraform_output "cognito_user_pool_id" 2>/dev/null) || cognito_pool_id="N/A"
        appsync_url=$(get_terraform_output "appsync_graphql_url" 2>/dev/null) || appsync_url="N/A"

        echo "  AppSync GraphQL: ${appsync_url}"
        echo "  Cognito Pool:    ${cognito_pool_id}"
        echo "  Lambda Functions: All deployed via Terraform"
        echo ""
    fi

    if [ "${DEPLOY_FRONTEND}" = "true" ]; then
        echo "Frontend: Configuration deployed"
        echo "  Trigger build via Amplify Console or push to repository"
        echo ""
    fi

    echo "Next Steps:"
    echo "  1. Verify deployment in AWS Console"
    echo "  2. Run integration tests: ./scripts/e2e-tests.sh"
    echo "  3. Create admin user: ./scripts/create-admin.sh"
    echo "  4. Monitor logs for any issues"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Automated Full Stack Deployment"
    echo ""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --skip-infrastructure)
                DEPLOY_INFRASTRUCTURE="false"
                shift
                ;;
            --skip-frontend)
                DEPLOY_FRONTEND="false"
                shift
                ;;
            --skip-build)
                SKIP_BUILD="true"
                shift
                ;;
            --infrastructure-only)
                DEPLOY_FRONTEND="false"
                shift
                ;;
            --frontend-only)
                DEPLOY_INFRASTRUCTURE="false"
                shift
                ;;
            -h|--help)
                cat << EOF
Usage: $(basename "$0") [OPTIONS]

Automated full stack deployment for AWS Serverless Task Manager.
Terraform now handles all Lambda deployments automatically.

OPTIONS:
    -e, --environment ENV        Deployment environment (sandbox/staging/production)
    --skip-infrastructure        Skip infrastructure & Lambda deployment
    --skip-frontend              Skip frontend deployment
    --skip-build                 Skip pre-building Lambda functions (use existing ZIPs)
    --infrastructure-only        Deploy only infrastructure & Lambdas
    --frontend-only              Deploy only frontend configuration
    -h, --help                   Show this help message

EXAMPLES:
    # Full deployment to sandbox
    $(basename "$0") -e sandbox

    # Deploy only infrastructure to production
    $(basename "$0") -e production --infrastructure-only

    # Deploy frontend only
    $(basename "$0") --frontend-only

    # Quick deploy (skip pre-build, let Terraform handle it)
    $(basename "$0") --skip-build

ENVIRONMENT VARIABLES:
    AWS_REGION          AWS region (default: eu-west-1)
    ENVIRONMENT         Deployment environment (default: sandbox)

NOTE:
    Lambda functions are now deployed via Terraform using a null_resource
    provisioner that automatically builds and deploys when source code changes.
    The --skip-build flag can speed up deployments if ZIPs are already current.

EOF
                exit 0
                ;;
            *)
                die "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done

    # Check prerequisites
    require_commands terraform aws jq npm zip
    check_aws_auth

    # Show deployment plan
    show_deployment_plan

    # Confirm deployment
    if [ "${CI:-false}" != "true" ]; then
        confirm "Proceed with deployment?" "y" || {
            log_info "Deployment cancelled"
            exit 0
        }
        echo ""
    fi

    # Execute deployment steps
    local start_time=$(date +%s)

    if [ "${DEPLOY_INFRASTRUCTURE}" = "true" ]; then
        deploy_infrastructure
        echo ""
    fi

    if [ "${DEPLOY_FRONTEND}" = "true" ]; then
        deploy_frontend
        echo ""
    fi

    # Run smoke tests
    run_smoke_tests
    echo ""

    # Calculate deployment time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    # Show summary
    show_deployment_summary

    log_success "Deployment completed in ${minutes}m ${seconds}s"
}

main "$@"
