#!/bin/bash

# Add user to Admins group
# Usage: ./add-user-to-admin.sh <user-email>

if [ -z "$1" ]; then
  echo "Usage: ./add-user-to-admin.sh <user-email>"
  exit 1
fi

USER_EMAIL=$1
USER_POOL_ID=$(cd terraform && terraform output -raw cognito_user_pool_id 2>/dev/null)

if [ -z "$USER_POOL_ID" ]; then
  echo "Error: Could not get user pool ID from Terraform"
  exit 1
fi

echo "Adding $USER_EMAIL to Admins group..."

aws cognito-idp admin-add-user-to-group \
  --user-pool-id "$USER_POOL_ID" \
  --username "$USER_EMAIL" \
  --group-name Admins

echo "✅ User added to Admins group successfully"
echo "Please log out and log back in for changes to take effect"
