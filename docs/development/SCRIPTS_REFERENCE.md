# Scripts Reference Guide

Quick reference for using the refactored shell scripts in the project.

## Common Library

All scripts now use the centralized common library at [scripts/lib/common.sh](scripts/lib/common.sh).

### Sourcing the Library

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
```

### Key Functions Available

#### Logging
```bash
log_debug "Debug message"          # Only shown with LOG_LEVEL=0
log_info "Informational message"   # Default
log_warn "Warning message"         # Warn about issues
log_error "Error message"          # Error message to stderr
log_success "Success message"      # Success indicator
die "Fatal error"                  # Log error and exit
```

#### Validation
```bash
require_command aws                      # Check single command
require_commands aws jq terraform        # Check multiple
require_directory "${dir}" "description" # Check directory exists
require_file "${file}" "description"     # Check file exists
validate_email "user@example.com"        # Validate email format
validate_aws_region "eu-west-1"          # Validate AWS region
```

#### Environment
```bash
load_env_file ".env"              # Load specific env file
load_project_env                  # Auto-load project .env
set_defaults                      # Set default AWS_REGION, etc.
```

#### AWS Helpers
```bash
check_aws_auth                                    # Verify AWS credentials
get_terraform_output "output_name"                # Get single output
get_terraform_outputs_json                        # Get all outputs as JSON
aws_resource_exists "aws s3 ls s3://bucket"       # Check resource exists
```

#### User Interaction
```bash
confirm "Continue?"                              # Prompt yes/no (default: no)
confirm "Proceed?" "y"                          # Default: yes
email=$(prompt_input "Email" validate_email)    # Prompt with validation
```

## Script Usage

### Core Scripts

#### build-lambdas.sh
Build all Lambda functions and layers.

```bash
./scripts/build-lambdas.sh
```

**What it does:**
- Builds shared Lambda layer
- Builds all 9 Lambda functions
- Creates deployment packages (function.zip)
- Installs dependencies for each function

**Output:** ZIP files ready for deployment in each Lambda directory

---

#### create-admin.sh
Create Cognito admin user.

```bash
./scripts/create-admin.sh
```

**Interactive prompts:**
- Admin email (validates @amalitech.com or @amalitechtraining.org)
- Generate or enter temporary password
- Optionally set permanent password
- Confirms operation before creating

**What it does:**
- Fetches User Pool ID from Terraform
- Creates Cognito user with verified email
- Adds user to Admins group
- Optionally sets permanent password

---

#### deploy-sns.sh
Deploy SNS notification system.

```bash
./scripts/deploy-sns.sh
```

**What it does:**
- Applies Terraform changes for SNS infrastructure
- Fetches SNS topic ARN
- Builds notification Lambda if needed
- Deploys notification handler Lambda

**Note:** Check email for SNS subscription confirmation

---

#### cleanup.sh
Clean build artifacts and dependencies.

```bash
# Standard cleanup (preserves Terraform cache)
./scripts/cleanup.sh

# Include Terraform cache cleanup
./scripts/cleanup.sh --terraform
```

**What it does:**
- Removes all node_modules directories
- Removes build artifacts (.next, build, dist, .cache)
- Removes Lambda deployment packages (*.zip)
- Removes Amplify artifacts
- Optionally removes Terraform cache (with --terraform flag)

---

#### setup-amplify.sh
Configure AWS Amplify deployment.

```bash
./scripts/setup-amplify.sh
```

**What it does:**
- Fetches Terraform outputs (User Pool, AppSync URL, etc.)
- Creates frontend/.env.local with environment variables
- Creates or updates Amplify app
- Configures Amplify environment variables

**Next steps after running:**
- Connect GitHub repository
- Trigger deployment from GitHub

---

#### verify-ses-email.sh
Verify email for SES.

```bash
./scripts/verify-ses-email.sh
```

**Interactive prompts:**
- Email address to verify

**What it does:**
- Checks current verification status
- Sends SES verification email if not verified
- Provides command to check status

---

### Environment Management

#### load-env.sh
Load project environment variables.

```bash
# Source in other scripts
source ./scripts/load-env.sh

# Now use environment variables
echo "${AWS_REGION}"
echo "${PROJECT_NAME}"
```

**What it does:**
- Sources common library
- Auto-loads .env file from project root
- Sets default values

---

## Environment Variables

### Default Values (set by common library)

```bash
AWS_REGION=eu-west-1
AWS_PAGER=               # Disable AWS CLI pager
PROJECT_NAME=task-manager
ENVIRONMENT=sandbox
```

### Logging Control

```bash
# Info level (default) - essential messages only
./scripts/build-lambdas.sh

# Debug level - verbose output
LOG_LEVEL=0 ./scripts/build-lambdas.sh

# Warning level - warnings and errors only
LOG_LEVEL=2 ./scripts/build-lambdas.sh

# Error level - errors only
LOG_LEVEL=3 ./scripts/build-lambdas.sh
```

**Log Levels:**
- `0` = DEBUG (most verbose)
- `1` = INFO (default, clear not verbose)
- `2` = WARN
- `3` = ERROR (least verbose)

---

## Script Patterns

### Standard Script Template

```bash
#!/bin/bash
# Script Name
# Brief description

set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# ============================================================================
# FUNCTIONS
# ============================================================================

my_function() {
    local param="$1"
    
    log_info "Doing something with ${param}"
    
    # Your logic here
    
    log_success "Done"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    log_info "Script Name"
    echo ""
    
    # Check prerequisites
    require_commands aws terraform jq
    check_aws_auth
    
    # Your main logic
    my_function "value"
    
    echo ""
    log_success "Complete"
}

main "$@"
```

### Error Handling Pattern

```bash
# Automatic exit on error (set -e)
command_that_might_fail || die "Failed to do something"

# Check return code explicitly
if ! some_command; then
    log_warn "Command failed, trying alternative"
    alternative_command || die "Both attempts failed"
fi

# Validate prerequisites upfront
require_directory "${dir}"
require_file "${file}"
check_aws_auth
```

### AWS CLI Best Practices

```bash
# Always use --no-cli-pager for automation
aws s3 ls --no-cli-pager

# Suppress output when checking existence
if aws s3 ls "s3://bucket" --no-cli-pager &>/dev/null; then
    log_info "Bucket exists"
fi

# Capture output and check for errors
local output
output=$(aws lambda list-functions --query 'Functions[].FunctionName' \
    --output text --no-cli-pager) || die "Failed to list functions"
```

---

## Troubleshooting

### Common Issues

#### "Required command 'X' not found"
**Solution:** Install the missing command
```bash
# For AWS CLI
pip install awscli

# For jq
sudo apt-get install jq  # Ubuntu/Debian
brew install jq          # macOS

# For Terraform
# Download from https://www.terraform.io/downloads
```

#### "AWS credentials not configured"
**Solution:** Configure AWS credentials
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region
```

#### "Failed to get Terraform output"
**Solution:** Run Terraform apply first
```bash
cd terraform
terraform init
terraform apply
```

#### "Directory not found"
**Solution:** Run script from correct location
```bash
# Scripts should be run from project root or scripts directory
cd /path/to/project
./scripts/scriptname.sh

# Or from scripts directory
cd /path/to/project/scripts
./scriptname.sh
```

---

## Best Practices

### When Writing New Scripts

1. **Always use fail-safe settings**
   ```bash
   set -euo pipefail
   ```

2. **Source common library first**
   ```bash
   source "${SCRIPT_DIR}/lib/common.sh"
   ```

3. **Check prerequisites upfront**
   ```bash
   require_commands aws terraform
   check_aws_auth
   ```

4. **Use functions for modularity**
   ```bash
   do_step_one() { ... }
   do_step_two() { ... }
   main() {
       do_step_one
       do_step_two
   }
   ```

5. **Log clearly, not verbosely**
   ```bash
   log_info "Building Lambda functions"  # What you're doing
   # ... do work ...
   log_success "Lambda functions built"  # Success confirmation
   ```

6. **Handle errors properly**
   ```bash
   command || die "Clear error message"
   ```

7. **Quote variables**
   ```bash
   "${variable}"      # Good
   $variable          # Bad (word splitting issues)
   ```

---

## Additional Scripts

Other scripts that can be refactored to use the common library:

- `add-user-to-admin.sh`
- `build-layer.sh`
- `check-user-groups.sh`
- `cleanup-eventbridge.sh`
- `create-resolvers.sh`
- `deploy-amplify-cli.sh`
- `e2e-tests.sh`
- `list-users.sh`
- `security-tests.sh`
- `setup-cicd.sh`
- `setup-remote-state.sh`
- `sns-setup-guide.sh`
- `upload-schema.sh`

---

## See Also

- [SCRIPTS_CLEANUP_SUMMARY.md](SCRIPTS_CLEANUP_SUMMARY.md) - Detailed cleanup documentation
- [scripts/lib/common.sh](scripts/lib/common.sh) - Common functions library source
- [README.md](README.md) - Project documentation

---

**Last Updated**: February 12, 2026  
**Status**: ✅ Production Ready
