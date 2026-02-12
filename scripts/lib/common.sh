#!/bin/bash
# Common Functions Library
# Provides shared utilities for all scripts in the project

# Fail-safe settings
set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONSTANTS
# ============================================================================

# Script paths
readonly SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR="$(dirname "${SCRIPT_LIB_DIR}")"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Colors for output
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GRAY='\033[0;90m'
readonly COLOR_RESET='\033[0m'

# Logging levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Current log level (can be overridden by scripts)
LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Log debug message (only if LOG_LEVEL allows)
log_debug() {
    if [ "${LOG_LEVEL}" -le "${LOG_LEVEL_DEBUG}" ]; then
        echo -e "${COLOR_GRAY}[DEBUG]${COLOR_RESET} $*" >&2
    fi
}

# Log informational message
log_info() {
    if [ "${LOG_LEVEL}" -le "${LOG_LEVEL_INFO}" ]; then
        echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
    fi
}

# Log warning message
log_warn() {
    if [ "${LOG_LEVEL}" -le "${LOG_LEVEL_WARN}" ]; then
        echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2
    fi
}

# Log error message
log_error() {
    if [ "${LOG_LEVEL}" -le "${LOG_LEVEL_ERROR}" ]; then
        echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
    fi
}

# Log success message
log_success() {
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} $*"
}

# Exit with error message
die() {
    log_error "$1"
    exit "${2:-1}"
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

# Check if command exists
require_command() {
    local cmd="$1"
    local package="${2:-$1}"

    if ! command -v "${cmd}" &> /dev/null; then
        die "Required command '${cmd}' not found. Install: ${package}"
    fi
}

# Check multiple required commands
require_commands() {
    local missing=()

    for cmd in "$@"; do
        if ! command -v "${cmd}" &> /dev/null; then
            missing+=("${cmd}")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        die "Missing required commands: ${missing[*]}"
    fi
}

# Check if directory exists
require_directory() {
    local dir="$1"
    local desc="${2:-directory}"

    if [ ! -d "${dir}" ]; then
        die "${desc} not found: ${dir}"
    fi
}

# Check if file exists
require_file() {
    local file="$1"
    local desc="${2:-file}"

    if [ ! -f "${file}" ]; then
        die "${desc} not found: ${file}"
    fi
}

# Validate email format
validate_email() {
    local email="$1"

    if [[ ! "${email}" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Validate AWS region format
validate_aws_region() {
    local region="$1"

    if [[ ! "${region}" =~ ^[a-z]{2}-[a-z]+-[0-9]{1}$ ]]; then
        return 1
    fi
    return 0
}

# ============================================================================
# ENVIRONMENT FUNCTIONS
# ============================================================================

# Load environment variables from file
load_env_file() {
    local env_file="${1:-.env}"

    if [ ! -f "${env_file}" ]; then
        log_warn "Environment file not found: ${env_file}"
        return 1
    fi

    log_debug "Loading environment from: ${env_file}"

    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "${key}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key}" ]] && continue

        # Remove leading/trailing whitespace and quotes
        key=$(echo "${key}" | xargs)
        value=$(echo "${value}" | xargs | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")

        # Export if not already set
        if [ -z "${!key:-}" ]; then
            export "${key}=${value}"
        fi
    done < "${env_file}"

    log_debug "Environment loaded successfully"
    return 0
}

# Auto-load project .env file
load_project_env() {
    local env_file="${PROJECT_ROOT}/.env"

    if [ -f "${env_file}" ]; then
        load_env_file "${env_file}"
    fi
}

# Set default environment variables
set_defaults() {
    export AWS_REGION="${AWS_REGION:-eu-west-1}"
    export AWS_PAGER="${AWS_PAGER:-}"
    export PROJECT_NAME="${PROJECT_NAME:-task-manager}"
    export ENVIRONMENT="${ENVIRONMENT:-sandbox}"
}

# ============================================================================
# AWS HELPER FUNCTIONS
# ============================================================================

# Check AWS CLI credentials are configured
check_aws_auth() {
    log_debug "Checking AWS credentials..."

    if ! aws sts get-caller-identity --no-cli-pager &> /dev/null; then
        die "AWS credentials not configured. Run: aws configure"
    fi

    log_debug "AWS credentials valid"
    return 0
}

# Get Terraform output value
get_terraform_output() {
    local output_name="$1"
    local terraform_dir="${2:-${PROJECT_ROOT}/terraform}"

    require_directory "${terraform_dir}" "Terraform directory"

    local value
    value=$(cd "${terraform_dir}" && terraform output -raw "${output_name}" 2>/dev/null) || {
        log_error "Failed to get Terraform output: ${output_name}"
        return 1
    }

    if [ -z "${value}" ]; then
        log_error "Terraform output '${output_name}' is empty"
        return 1
    fi

    echo "${value}"
}

# Get all Terraform outputs as JSON
get_terraform_outputs_json() {
    local terraform_dir="${1:-${PROJECT_ROOT}/terraform}"

    require_directory "${terraform_dir}" "Terraform directory"

    local outputs
    outputs=$(cd "${terraform_dir}" && terraform output -json 2>/dev/null) || {
        die "Failed to get Terraform outputs"
    }

    echo "${outputs}"
}

# Check if AWS resource exists (generic)
aws_resource_exists() {
    local check_command="$*"

    if eval "${check_command}" &> /dev/null; then
        return 0
    fi
    return 1
}

# ============================================================================
# FILE SYSTEM HELPERS
# ============================================================================

# Create directory if it doesn't exist
ensure_directory() {
    local dir="$1"

    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}"
        log_debug "Created directory: ${dir}"
    fi
}

# Clean directory contents
clean_directory() {
    local dir="$1"

    if [ -d "${dir}" ]; then
        rm -rf "${dir:?}"/*
        log_debug "Cleaned directory: ${dir}"
    fi
}

# Create backup of file
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if [ -f "${file}" ]; then
        cp "${file}" "${backup}"
        log_debug "Created backup: ${backup}"
        echo "${backup}"
    fi
}

# ============================================================================
# USER INTERACTION
# ============================================================================

# Prompt for user confirmation
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"

    local response
    if [ "${default}" = "y" ]; then
        read -r -p "${prompt} [Y/n]: " response
        response="${response:-y}"
    else
        read -r -p "${prompt} [y/N]: " response
        response="${response:-n}"
    fi

    case "${response}" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# Prompt for input with validation
prompt_input() {
    local prompt="$1"
    local validator="${2:-}"
    local value=""

    while true; do
        read -r -p "${prompt}: " value

        if [ -z "${value}" ]; then
            log_error "Value cannot be empty"
            continue
        fi

        if [ -n "${validator}" ] && ! ${validator} "${value}"; then
            log_error "Invalid input"
            continue
        fi

        break
    done

    echo "${value}"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize common library (called automatically)
init_common() {
    # Set defaults
    set_defaults

    # Auto-load project environment if not in lib directory
    if [ "$(basename "$(pwd)")" != "lib" ]; then
        load_project_env || true
    fi
}

# Auto-initialize when sourced
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    init_common
fi
