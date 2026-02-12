#!/bin/bash
# Lambda Build Script
# Packages Lambda functions with dependencies for deployment

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

readonly LAMBDA_DIR="${PROJECT_ROOT}/lambda"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Build single Lambda function
build_lambda() {
    local function_name="$1"
    local function_dir="${LAMBDA_DIR}/${function_name}"
    
    log_info "Building ${function_name}"
    
    require_directory "${function_dir}" "Lambda directory"
    cd "${function_dir}"
    
    # Install dependencies if package.json exists
    if [ -f package.json ]; then
        log_debug "Installing dependencies"
        npm install --production --silent || die "Failed to install dependencies for ${function_name}"
    fi
    
    # Remove old package
    rm -f function.zip
    
    # Package function with dependencies
    if [ -d node_modules ]; then
        zip -qr function.zip index.js package.json node_modules/ \
            || die "Failed to package ${function_name}"
    else
        zip -q function.zip index.js package.json \
            || die "Failed to package ${function_name}"
    fi
    
    log_success "${function_name} built"
}

# Build Lambda layer
build_layer() {
    local layer_dir="${LAMBDA_DIR}/layers/shared-layer"
    
    log_info "Building shared Lambda layer"
    
    require_directory "${layer_dir}" "Layer directory"
    cd "${layer_dir}"
    
    # Install dependencies
    if [ -f package.json ]; then
        log_debug "Installing layer dependencies"
        npm install --production --silent || die "Failed to install layer dependencies"
    fi
    
    # Create nodejs directory structure for Lambda layer
    mkdir -p nodejs
    
    # Copy node_modules and utilities
    [ -d node_modules ] && cp -r node_modules nodejs/
    find . -maxdepth 1 -name "*.js" -exec cp {} nodejs/ \; 2>/dev/null || true
    
    # Remove old package
    rm -f ../shared-layer.zip
    
    # Package layer
    zip -qr ../shared-layer.zip nodejs/ || die "Failed to package layer"
    
    # Cleanup
    rm -rf nodejs
    
    log_success "Lambda layer built"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Build Lambda Functions"
    echo ""
    
    # Check prerequisites
    require_commands npm zip
    require_directory "${LAMBDA_DIR}" "Lambda directory"
    
    # Build Lambda layer first
    build_layer
    echo ""
    
    # Lambda functions to build
    local functions=(
        "pre-signup-trigger"
        "task-api"
        "notification-handler"
        "users-api"
        "appsync-resolver"
        "stream-processor"
        "file-processor"
        "presigned-url"
        "github-webhook"
    )
    
    # Build each function
    for func in "${functions[@]}"; do
        build_lambda "${func}"
    done
    
    echo ""
    log_success "All Lambda functions built successfully"
    echo ""
    log_info "Deployment packages ready in ${LAMBDA_DIR}"
}

main "$@"
