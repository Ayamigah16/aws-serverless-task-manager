# AWS Amplify Deployment - Quick Start

Deploy your frontend to AWS Amplify using Terraform with automatic Secrets Manager integration.

## How It Works

1. **First Run**: Provide GitHub token → Terraform stores it in AWS Secrets Manager
2. **Subsequent Runs**: Token automatically read from Secrets Manager
3. **Token Rotation**: Update token value → Terraform updates Secrets Manager

## Prerequisites

1. GitHub Personal Access Token with `repo` scope
   - Create at: https://github.com/settings/tokens
   - Select "Generate new token (classic)"
   - Check the `repo` scope
   - Copy the token (starts with `ghp_`)

2. GitHub Repository
   - Your code should be in a GitHub repository
   - Repository must be accessible with the token

## Quick Setup

### Option 1: Interactive Script (Recommended)

```bash
npm run setup:amplify
```

The script will:
- Prompt for repository URL
- Ask for branch names (main/dev)
- Request GitHub token (stored securely)
- Configure Terraform
- Deploy to AWS Amplify
- Show deployment URLs

### Option 2: Manual Configuration

1. **Edit `terraform/terraform.tfvars`**:

```hcl
enable_amplify_deployment = true
github_repository_url     = "https://github.com/your-org/aws-serverless-task-manager"
github_main_branch        = "main"
github_dev_branch         = "dev"
amplify_enable_auto_build = true
```

2. **Set GitHub token** (choose one method):

```bash
# Method A: Environment variable (recommended)
export TF_VAR_github_access_token="ghp_xxxxxxxxxxxxxxxxxxxx"

# Method B: Direct in tfvars (not recommended - don't commit!)
# github_access_token = "ghp_xxxxxxxxxxxxxxxxxxxx"
```

3. **Deploy**:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Token Management

### View Current Configuration

```bash
npm run setup:amplify  # Then select "Show current config"
```

Or manually:

```bash
cd terraform
terraform output github_token_secret_name
terraform output amplify_app_id
terraform output amplify_main_branch_url
```

### Rotate GitHub Token

When you need to update the token (e.g., token expired, security rotation):

```bash
npm run setup:amplify  # Then select "Rotate GitHub token"
```

Or manually:

```bash
# Set new token
export TF_VAR_github_access_token="ghp_NEW_TOKEN_HERE"

# Apply - Terraform will update Secrets Manager
cd terraform
terraform apply -auto-approve
```

### Check Token in Secrets Manager

```bash
# Get secret name
SECRET_NAME=$(cd terraform && terraform output -raw github_token_secret_name)

# Retrieve token (careful - this displays the token!)
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query SecretString \
  --output text
```

## Deployment URLs

After deployment, get your URLs:

```bash
cd terraform

# Main branch (production)
terraform output amplify_main_branch_url

# Dev branch
terraform output amplify_dev_branch_url

# App ID (for AWS Console)
terraform output amplify_app_id
```

## Automatic Deployments

Once configured, Amplify automatically:
- **Builds on push** to main or dev branches
- **Runs tests** defined in amplify.yml
- **Deploys** to respective URLs
- **Notifies** on build status

### Trigger Manual Build

```bash
APP_ID=$(cd terraform && terraform output -raw amplify_app_id)

aws amplify start-job \
  --app-id "$APP_ID" \
  --branch-name main \
  --job-type RELEASE \
  --region eu-west-1
```

## Custom Domain (Optional)

To use your own domain:

1. **Update terraform.tfvars**:
```hcl
amplify_custom_domain = "taskmanager.example.com"
```

2. **Apply changes**:
```bash
cd terraform
terraform apply
```

3. **Add DNS records**:
```bash
# Get DNS verification records
APP_ID=$(terraform output -raw amplify_app_id)
aws amplify get-domain-association \
  --app-id "$APP_ID" \
  --domain-name taskmanager.example.com

# Add the CNAME records to your DNS provider
```

## Troubleshooting

### Build Fails

Check logs in AWS Console or CLI:

```bash
APP_ID=$(cd terraform && terraform output -raw amplify_app_id)

aws amplify list-jobs \
  --app-id "$APP_ID" \
  --branch-name main \
  --region eu-west-1

# Get specific job details
aws amplify get-job \
  --app-id "$APP_ID" \
  --branch-name main \
  --job-id <JOB_ID>
```

### Token Invalid

Rotate the token:

```bash
npm run setup:amplify  # Select "Rotate GitHub token"
```

### Environment Variables Not Set

Verify in Amplify:

```bash
APP_ID=$(cd terraform && terraform output -raw amplify_app_id)
aws amplify get-app --app-id "$APP_ID" \
  --query 'app.environmentVariables'
```

### Can't Access Secrets Manager

Ensure your AWS credentials have permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue",
    "secretsmanager:PutSecretValue",
    "secretsmanager:CreateSecret"
  ],
  "Resource": "arn:aws:secretsmanager:*:*:secret:task-manager-*"
}
```

## Security Best Practices

1. **Never commit tokens** to git
2. **Use environment variables** for local development
3. **Rotate tokens** every 90 days minimum
4. **Limit token scope** to only `repo` access
5. **Monitor token usage** in GitHub settings
6. **Enable branch protection** on main branch
7. **Review access logs** in AWS CloudTrail

## Cleanup

To remove Amplify deployment:

```bash
cd terraform

# Option 1: Disable in tfvars
# Set: enable_amplify_deployment = false
terraform apply

# Option 2: Destroy everything
terraform destroy
```

This will also delete the GitHub token from Secrets Manager.

## Cost Estimate

AWS Amplify Hosting pricing (as of 2026):
- **Build minutes**: $0.01/minute
- **Data served**: $0.15/GB
- **Storage**: $0.023/GB/month

Typical monthly cost for low-traffic app: **$1-5**

## Support

- **AWS Amplify Docs**: https://docs.aws.amazon.com/amplify/
- **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/amplify_app
- **GitHub Token Guide**: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token
