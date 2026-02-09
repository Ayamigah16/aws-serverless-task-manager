#!/bin/bash

set -e

REGION="eu-west-1"

echo "========================================="
echo "SES Email Verification Script"
echo "========================================="
echo ""

read -p "Enter the email address to verify for SES: " EMAIL

if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "❌ Invalid email format"
    exit 1
fi

echo ""
echo "Verifying email: $EMAIL in region: $REGION"
echo ""

aws ses verify-email-identity --email-address "$EMAIL" --region "$REGION"

echo ""
echo "✅ Verification email sent to: $EMAIL"
echo ""
echo "📧 Check your inbox and click the verification link"
echo ""
echo "To check verification status, run:"
echo "aws ses get-identity-verification-attributes --identities $EMAIL --region $REGION"
echo ""
