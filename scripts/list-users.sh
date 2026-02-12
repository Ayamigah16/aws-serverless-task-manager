#!/bin/bash

# List Users Script
# Shows all users with their IDs for task assignment

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

# Get values from environment or Terraform output
AWS_REGION="${AWS_REGION:-$(aws configure get region || echo 'eu-west-1')}"
USER_POOL_ID="${COGNITO_USER_POOL_ID:-${1}}"

if [ -z "$USER_POOL_ID" ]; then
  echo "Error: User Pool ID required"
  echo "Usage: $0 <user-pool-id>"
  echo "Or set COGNITO_USER_POOL_ID environment variable"
  exit 1
fi

echo -e "${GREEN}Users in pool: ${USER_POOL_ID}${NC}"
echo "=================================="

aws cognito-idp list-users \
  --user-pool-id "${USER_POOL_ID}" \
  --region "${AWS_REGION}" \
  --query 'Users[*].[Username, Attributes[?Name==`sub`].Value | [0], Attributes[?Name==`email`].Value | [0]]' \
  --output table

echo ""
echo "To assign a task, copy the User ID (middle column)"
