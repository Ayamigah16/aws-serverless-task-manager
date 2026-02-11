#!/bin/bash

set -e

echo "🚀 Deploying to AWS Amplify via CLI..."

# Install Amplify CLI if not installed
if ! command -v amplify &> /dev/null; then
    echo "📦 Installing Amplify CLI..."
    npm install -g @aws-amplify/cli
fi

cd frontend

# Initialize Amplify (if not already initialized)
if [ ! -d "amplify" ]; then
    echo "🔧 Initializing Amplify..."
    amplify init --yes \
        --amplify '{"projectName":"taskmanager","envName":"prod","defaultEditor":"code"}' \
        --frontend '{"frontend":"javascript","framework":"react","config":{"SourceDir":"src","DistributionDir":".next","BuildCommand":"npm run build","StartCommand":"npm run dev"}}' \
        --providers '{"awscloudformation":{"useProfile":true,"profileName":"default"}}'
fi

# Add hosting
if ! amplify status | grep -q "Hosting"; then
    echo "🌐 Adding hosting..."
    amplify add hosting --yes
fi

# Build and publish
echo "📦 Building and deploying..."
npm run build
amplify publish --yes

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next: Update Cognito callback URLs with your Amplify URL"
