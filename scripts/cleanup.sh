#!/bin/bash

echo "🧹 Cleaning up codebase..."

# Remove node_modules
find . -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null
echo "✅ Removed node_modules"

# Remove build artifacts
find . -name ".next" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name "build" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name "dist" -type d -prune -exec rm -rf {} + 2>/dev/null
echo "✅ Removed build artifacts"

# Remove Lambda zips
find lambda -name "*.zip" -type f -delete 2>/dev/null
echo "✅ Removed Lambda deployment packages"

# Remove Amplify artifacts
rm -rf frontend/amplify 2>/dev/null
rm -rf frontend/.amplify 2>/dev/null
echo "✅ Removed Amplify artifacts"

# Remove Terraform state (optional - uncomment if needed)
# rm -rf terraform/.terraform 2>/dev/null
# rm -f terraform/.terraform.lock.hcl 2>/dev/null
# echo "✅ Removed Terraform cache"

echo ""
echo "🎉 Cleanup complete!"
