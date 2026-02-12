# AWS Amplify Secure Deployment Guide

This guide explains how to deploy your frontend to AWS Amplify using Terraform with **secure GitHub token management**. The token is stored externally in AWS Secrets Manager and **never** appears in Terraform files or state.

## 🔒 Security Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  External Script (create-github-secret.sh)                  │
│  • Prompts for GitHub token securely                        │
│  • Stores in AWS Secrets Manager                            │
│  • Token never touches Terraform                            │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    ▼
           ┌─────────────────┐
           │ AWS Secrets     │
           │ Manager         │◄──────────────────┐
           └────────┬────────┘                   │
                    │                            │
                    │ Terraform reads            │ Script updates
                    │ (data source)              │ (on rotation)
                    │                            │
                    ▼                            │
           ┌─────────────────┐          ┌────────────────┐
           │ Terraform       │          │ Rotate Token   │
           │ • References    │          │ (re-run script)│
           │   secret by name│          └────────────────┘
           │ • No token in   │
           │   files/state   │
           └────────┬────────┘
                    │
                    ▼
           ┌─────────────────┐
           │ AWS Amplify     │
           │ • Reads token   │
           │   from secret   │
           │ • Deploys app   │
           └─────────────────┘
```

## 📋 Prerequisites

1. **GitHub Personal Access Token**
   - Create at: https://github.com/settings/tokens/new
   - Required scope: `repo` (Full control of private repositories)
   - Save the token securely (you'll need it once)

2. **AWS Credentials**
   - AWS CLI configured with appropriate permissions
   - Access to AWS Secrets Manager, Amplify, and IAM

3. **Infrastructure Deployed**
   - Run `./scripts/deploy.sh --environment sandbox` first
   - This creates Cognito, AppSync, DynamoDB, etc.

## 🚀 Quick Start

### Step 1: Create GitHub Token Secret

Run the script to securely store your GitHub token:

```bash
./scripts/create-github-secret.sh
```

**What happens:**
- Prompts for your GitHub token (hidden input)
- Creates/updates secret in AWS Secrets Manager
- Token is encrypted at rest using AWS KMS
- Token **never** appears in any file or terminal history

**Output:**
```
Secret Details:
  Name: task-manager-github-token
  Region: eu-west-1

Next Steps:
  1. Update terraform.tfvars with:
     github_secret_name = "task-manager-github-token"
  
  2. Deploy Amplify with Terraform:
     cd terraform && terraform apply
```

### Step 2: Configure Amplify Deployment

Use the interactive setup script:

```bash
./scripts/setup-amplify-deployment.sh
```

Or manually update `terraform/terraform.tfvars`:

```hcl
enable_amplify_deployment = true
github_repository_url     = "https://github.com/your-org/aws-serverless-task-manager"
github_secret_name        = "task-manager-github-token"  # From Step 1
github_main_branch        = "main"
github_dev_branch         = "dev"
```

### Step 3: Deploy Frontend

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Terraform will:**
- Read the GitHub token from Secrets Manager (by name)
- Create AWS Amplify app
- Configure build settings
- Set environment variables
- Deploy your frontend

**No token appears in:**
- ✅ Terraform state files
- ✅ Terraform plan output
- ✅ Terminal output
- ✅ Git repository
- ✅ CI/CD logs

## 🔄 Rotating the GitHub Token

When you need to rotate your GitHub token (e.g., expiration, security incident):

```bash
./scripts/create-github-secret.sh ##
```

**What happens:**
1. Script updates the existing secret in Secrets Manager
2. AWS Amplify automatically uses the new token
3. **No Terraform changes needed**
4. No downtime or manual intervention

The token rotation is **completely decoupled** from infrastructure changes.

## 📂 File Structure

```
aws-serverless-task-manager/
├── scripts/
│   ├── create-github-secret.sh          # Creates secret in AWS
│   └── setup-amplify-deployment.sh      # Interactive setup wizard
├── terraform/
│   ├── main.tf                          # Amplify module (no secrets!)
│   ├── terraform.tfvars                 # Config (no token!)
│   └── modules/
│       └── amplify/
│           ├── main.tf                  # Uses data source for secret
│           ├── variables.tf             # github_secret_name (not token!)
│           └── outputs.tf
└── docs/
    └── deployment/
        └── AMPLIFY_SECURE_DEPLOYMENT.md # This file
```

## 🔐 Security Best Practices

### ✅ DO

- Store token in AWS Secrets Manager using the provided script
- Use IAM roles with least-privilege for Secrets Manager access
- Enable AWS CloudTrail to audit secret access
- Consider using AWS Secrets Manager automatic rotation
- Use different secrets for different environments
- Revoke and rotate tokens regularly

### ❌ DON'T

- Commit tokens to Git (even in `.gitignore`d files)
- Pass tokens via command line (visible in `ps` output)
- Store tokens in environment variables long-term
- Share tokens between environments
- Use long-lived tokens (prefer fine-grained tokens with expiration)

## 🛠️ Troubleshooting

### Secret Not Found

```bash
Error: reading Secrets Manager Secret: ResourceNotFoundException
```

**Solution:** Run `./scripts/create-github-secret.sh` first to create the secret.

### Invalid Token

```bash
Error: Amplify: Access token validation failed
```

**Solutions:**
1. Verify token has `repo` scope
2. Check token hasn't expired
3. Ensure token is for the correct GitHub account
4. Rotate token using `./scripts/create-github-secret.sh`

### Permission Denied

```bash
Error: operation error Secrets Manager: GetSecretValue, access denied
```

**Solution:** Add IAM permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "secretsmanager:GetSecretValue",
    "secretsmanager:DescribeSecret"
  ],
  "Resource": "arn:aws:secretsmanager:*:*:secret:task-manager-github-token-*"
}
```

### Terraform State Contains Old Token

If you previously used the approach where Terraform managed the secret:

```bash
# Remove old secret resources from state
terraform state rm module.amplify[0].aws_secretsmanager_secret.github_token
terraform state rm module.amplify[0].aws_secretsmanager_secret_version.github_token

# Remove old secrets module if it exists
terraform state rm module.secrets[0]

# Re-import if needed
terraform import 'module.amplify[0].data.aws_secretsmanager_secret.github_token' task-manager-github-token
```

## 📊 Cost Estimate

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| AWS Secrets Manager | 1 secret | $0.40 |
| AWS Secrets Manager API | ~1000 calls | $0.05 |
| AWS Amplify | Depends on traffic | Variable |
| **Total (secrets only)** | | **~$0.45/month** |

*Secrets Manager: $0.40/secret/month + $0.05 per 10,000 API calls*

## 🔍 Advanced Topics

### Using Different Secret Names per Environment

```hcl
# terraform/environments/production.tfvars
github_secret_name = "task-manager-github-token-prod"

# terraform/environments/sandbox.tfvars
github_secret_name = "task-manager-github-token-sandbox"
```

Create separate secrets:

```bash
AWS_REGION=eu-west-1 ./scripts/create-github-secret.sh --secret-name task-manager-github-token-prod
AWS_REGION=eu-west-1 ./scripts/create-github-secret.sh --secret-name task-manager-github-token-sandbox
```

### Automatic Secret Rotation (Optional)

Enable AWS Secrets Manager automatic rotation:

```bash
aws secretsmanager rotate-secret \
  --secret-id task-manager-github-token \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

*Note: Requires a Lambda function to generate new GitHub tokens via API*

### CI/CD Integration

GitHub Actions workflow:

```yaml
- name: Deploy Amplify Frontend
  env:
    AWS_REGION: eu-west-1
    TF_VAR_github_secret_name: task-manager-github-token
  run: |
    cd terraform
    terraform init
    terraform apply -auto-approve
```

**Note:** No token environment variable needed! Terraform reads from Secrets Manager.

## 📚 Related Documentation

- [Main Deployment Guide](../ENHANCED_DEPLOYMENT_GUIDE.md)
- [Frontend Deployment](FRONTEND_DEPLOYMENT.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)
- [AWS Secrets Manager Best Practices](https://docs.aws.amazon.com/secretsmanager/latest/userguide/best-practices.html)

## 🤝 Support

For issues:
1. Check [Troubleshooting](#-troubleshooting) section above
2. Review AWS Secrets Manager console for secret status
3. Check Terraform plan output for data source errors
4. Verify IAM permissions for Secrets Manager access

---

**Remember:** The token is stored securely in AWS Secrets Manager. You only need to provide it once during initial setup or when rotating. Terraform never needs the actual token value!
