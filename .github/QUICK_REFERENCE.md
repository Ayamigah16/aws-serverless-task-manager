# CI/CD Quick Reference

## 🚀 Quick Commands

### Deploy via GitHub Actions

```bash
# Full stack deployment
gh workflow run deploy.yml -f environment=sandbox

# Infrastructure only
gh workflow run terraform-deploy.yml -f environment=sandbox -f action=apply

# Lambda functions only
gh workflow run lambda-deploy.yml -f environment=sandbox

# Frontend only
gh workflow run frontend-deploy.yml -f environment=sandbox

# Run tests
gh workflow run test.yml -f test_type=all
```

### Monitor Deployments

```bash
# Watch active deployment
gh run watch

# List recent runs
gh run list --limit 10

# View specific run with logs
gh run view <RUN_ID> --log

# View in browser
gh run view --web
```

### Local Development

```bash
# Build all Lambda functions
./scripts/build-lambdas.sh

# Build Lambda layer
./scripts/build-layer.sh

# Run frontend locally
cd frontend && npm run dev

# Run tests
npm test
```

## 📋 Common Workflows

### Create Feature

```bash
git checkout -b feature/my-feature
# Make changes
git commit -am "feat: Add new feature"
git push origin feature/my-feature
# Create PR → CI runs automatically
```

### Deploy to Staging

```bash
git checkout develop
git merge feature/my-feature
git push origin develop
# Auto-deploys to staging
```

### Deploy to Production

```bash
git checkout main
git merge develop
git push origin main
# Auto-deploys to production (with approval)
```

### Rollback

```bash
# Find last successful run
gh run list --workflow=deploy.yml --status=success --limit 1

# Re-run it
gh run rerun <RUN_ID>

# Or revert commit
git revert HEAD
git push
```

## 🔑 Required Secrets

### Repository Secrets
- `AWS_ROLE_ARN` - IAM role for deployments
- `TF_STATE_BUCKET` - Terraform state bucket
- `TF_STATE_LOCK_TABLE` - State lock table

### Environment Secrets (per env)
- `API_URL` - API Gateway URL
- `COGNITO_USER_POOL_ID` - User Pool ID
- `COGNITO_CLIENT_ID` - Client ID
- `FRONTEND_URL` - Frontend URL

### Optional Secrets
- `SLACK_WEBHOOK_URL` - Slack notifications
- `TEST_USER_EMAIL` - E2E test user
- `TEST_USER_PASSWORD` - E2E test password

## 🌍 Environments

| Environment | Branch | Auto-Deploy |
|-------------|--------|-------------|
| Sandbox | feature/* | No |
| Staging | develop | Yes |
| Production | main | Yes (with approval) |

## 🐛 Troubleshooting

### Authentication Error
```bash
# Check role ARN
aws iam get-role --role-name GitHubActionsDeploymentRole

# Verify OIDC provider
aws iam list-open-id-connect-providers
```

### Terraform State Lock
```bash
# List locks
aws dynamodb scan --table-name task-manager-terraform-locks

# Force unlock (use with caution)
cd terraform && terraform force-unlock <LOCK_ID>
```

### Lambda Deployment Failed
```bash
# Check function exists
aws lambda get-function --function-name task-manager-ENV-FUNCTION

# Check logs
aws logs tail /aws/lambda/task-manager-ENV-FUNCTION --follow
```

### Frontend Build Failed
```bash
# Check Terraform outputs
cd terraform && terraform output -json

# Verify environment variables
gh secret list --env sandbox
```

## 📊 Status Checks

### Required for PRs
- ✓ Unit Tests
- ✓ Terraform Validation
- ✓ Lint & Format
- ✓ Security Scans

### Optional for PRs
- Integration Tests (label: `run-integration-tests`)
- E2E Tests (label: `run-e2e-tests`)

## 🔗 Useful Links

- **CI/CD Guide**: [docs/CI_CD_GUIDE.md](../docs/CI_CD_GUIDE.md)
- **Secrets Template**: [.github/SECRETS_TEMPLATE.md](./SECRETS_TEMPLATE.md)
- **Implementation**: [CI_CD_IMPLEMENTATION.md](../CI_CD_IMPLEMENTATION.md)
- **GitHub Actions**: https://github.com/YOUR_ORG/YOUR_REPO/actions

## 🆘 Getting Help

1. Check workflow logs in GitHub Actions
2. Review [CI/CD Guide](../docs/CI_CD_GUIDE.md)
3. Check AWS CloudWatch logs
4. Create GitHub issue

---

**For detailed documentation, see [docs/CI_CD_GUIDE.md](../docs/CI_CD_GUIDE.md)**
