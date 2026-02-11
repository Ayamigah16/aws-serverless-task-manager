#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./check-user-groups.sh <user-email>"
  exit 1
fi

USER_EMAIL=$1
USER_POOL_ID=$(cd terraform && terraform output -raw cognito_user_pool_id 2>/dev/null)

echo "Checking groups for: $USER_EMAIL"
echo "User Pool ID: $USER_POOL_ID"
echo ""

aws cognito-idp admin-list-groups-for-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USER_EMAIL" \
  --query "Groups[].GroupName" \
  --output table
