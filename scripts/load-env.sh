#!/bin/bash
# Load Environment Variables Helper
# Source this in other scripts to load project environment

set -euo pipefail

# Source common  functions (which will auto-load .env)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

# Export this script as sourced if needed
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    log_debug "Environment loaded via load-env.sh"
fi
