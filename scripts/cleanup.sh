#!/bin/bash
# Cleanup Script
# Removes build artifacts, dependencies, and temporary files

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

# Remove node_modules directories
clean_node_modules() {
    log_info "Removing node_modules"

    find "${PROJECT_ROOT}" -name "node_modules" -type d -prune \
        -exec rm -rf {} + 2>/dev/null || true

    log_success "Removed node_modules"
}

# Remove build artifacts
clean_build_artifacts() {
    log_info "Removing build artifacts"

    find "${PROJECT_ROOT}" -type d \( \
        -name ".next" -o \
        -name "build" -o \
        -name "dist" -o \
        -name ".cache" \
        \) -prune -exec rm -rf {} + 2>/dev/null || true

    log_success "Removed build artifacts"
}

# Remove Lambda packages
clean_lambda_packages() {
    log_info "Removing Lambda packages"

    if [ -d "${PROJECT_ROOT}/lambda" ]; then
        find "${PROJECT_ROOT}/lambda" -name "*.zip" -type f \
            -delete 2>/dev/null || true
    fi

    log_success "Removed Lambda packages"
}

# Remove Amplify artifacts
clean_amplify_artifacts() {
    log_info "Removing Amplify artifacts"

    rm -rf "${PROJECT_ROOT}/frontend/amplify" 2>/dev/null || true
    rm -rf "${PROJECT_ROOT}/frontend/.amplify" 2>/dev/null || true

    log_success "Removed Amplify artifacts"
}

# Clean Terraform cache (optional)
clean_terraform_cache() {
    if [ "${1:-}" = "--terraform" ]; then
        log_warn "Removing Terraform cache"

        rm -rf "${PROJECT_ROOT}/terraform/.terraform" 2>/dev/null || true
        rm -f "${PROJECT_ROOT}/terraform/.terraform.lock.hcl" 2>/dev/null || true

        log_success "Removed Terraform cache"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Cleanup Codebase"
    echo ""

    # Perform cleanup
    clean_node_modules
    clean_build_artifacts
    clean_lambda_packages
    clean_amplify_artifacts
    clean_terraform_cache "$@"

    echo ""
    log_success "Cleanup complete"

    if [ "${1:-}" != "--terraform" ]; then
        echo ""
        log_info "Run with --terraform to also remove Terraform cache"
    fi
}

main "$@"
