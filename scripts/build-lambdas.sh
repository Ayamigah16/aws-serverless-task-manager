#!/bin/bash

# Lambda Build Script
# Packages Lambda functions with dependencies for deployment

set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly LAMBDA_DIR="${PROJECT_ROOT}/lambda"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $*"
}

error_exit() {
    log_error "$1"
    exit "${2:-1}"
}

# Check if directory exists
check_directory() {
    local dir="$1"
    if [[ ! -d "${dir}" ]]; then
        error_exit "Directory not found: ${dir}"
    fi
}

# Build Lambda function
build_lambda() {
    local function_name="$1"
    local function_dir="${LAMBDA_DIR}/${function_name}"
    
    log_info "Building ${function_name}..."
    
    check_directory "${function_dir}"
    
    cd "${function_dir}" || error_exit "Failed to cd to ${function_dir}"
    
    # Remove old package
    rm -f function.zip
    
    # Package function (all functions now use Lambda layer for shared code)
    zip -q function.zip index.js package.json || error_exit "Failed to package ${function_name}"
    
    log_success "${function_name} built successfully"
}

# Build Lambda layer
build_layer() {
    log_info "Building Lambda layer..."
    
    local layer_dir="${LAMBDA_DIR}/layers/shared-layer"
    check_directory "${layer_dir}"
    
    cd "${layer_dir}" || error_exit "Failed to cd to ${layer_dir}"
    
    # Remove old package
    rm -f ../shared-layer.zip
    
    # Package layer
    zip -qr ../shared-layer.zip nodejs/ || error_exit "Failed to package layer"
    
    log_success "Lambda layer built successfully"
}

# Main function
main() {
    log_info "Starting Lambda build process"
    echo "========================================"
    
    # Check lambda directory exists
    check_directory "${LAMBDA_DIR}"
    
    # Build Lambda layer first
    build_layer
    
    # Build each Lambda function
    build_lambda "pre-signup-trigger"
    build_lambda "task-api"
    build_lambda "notification-handler"
    
    echo ""
    echo "========================================"
    log_success "All Lambda functions built successfully!"
    echo "========================================"
    echo ""
    log_info "Deployment packages created:"
    echo "  - ${LAMBDA_DIR}/layers/shared-layer.zip"
    echo "  - ${LAMBDA_DIR}/pre-signup-trigger/function.zip"
    echo "  - ${LAMBDA_DIR}/task-api/function.zip"
    echo "  - ${LAMBDA_DIR}/notification-handler/function.zip"
    echo ""
}

# Run main function
main "$@"
