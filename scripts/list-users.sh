#!/bin/bash

# List Users Script
# Shows all users with their IDs for task assignment

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

USER_POOL_ID="${1:-eu-west-1_UpNnozW0k}"

echo -e "${GREEN}Users in pool: ${USER_POOL_ID}${NC}"
echo "=================================="

aws cognito-idp list-users \
  --user-pool-id "${USER_POOL_ID}" \
  --region eu-west-1 \
  --query 'Users[*].[Username, Attributes[?Name==`sub`].Value | [0], Attributes[?Name==`email`].Value | [0]]' \
  --output table

echo ""
echo "To assign a task, copy the User ID (middle column)"
