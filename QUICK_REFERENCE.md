# 🚀 Quick Deployment Reference

## One-Command Deployment

```bash
# Deploy entire stack to sandbox
./scripts/deploy.sh -e sandbox

# Deploy to production
./scripts/deploy.sh -e production

# Deploy only what changed
./scripts/deploy.sh -e staging --skip-infrastructure
```

## Component Deployment

```bash
# Infrastructure only (5-10 min)
./scripts/deploy.sh --infrastructure-only

# Lambdas only (3-5 min)
./scripts/deploy.sh --lambdas-only

# Frontend only (10-15 min)
./scripts/deploy.sh --frontend-only
```

## CI/CD Deployment

```bash
# Auto-deploy by pushing
git push origin main      # → production
git push origin develop   # → staging

# Manual trigger
gh workflow run deploy.yml -f environment=production
```

## Common Tasks

```bash
# Build Lambda functions
./scripts/build-lambdas.sh

# Create admin user
./scripts/create-admin.sh

# Setup Amplify
./scripts/setup-amplify.sh

# Clean up artifacts
./scripts/cleanup.sh

# Verify SES email
./scripts/verify-ses-email.sh

# Deploy SNS
./scripts/deploy-sns.sh
```

## Monitoring & Testing

```bash
# Run E2E tests
./scripts/e2e-tests.sh

# Watch CI/CD workflow
gh run watch

# View Lambda logs
aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow

# Check deployment status
gh workflow list
```

## Troubleshooting

```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate Terraform
cd terraform && terraform validate

# Check Terraform outputs
cd terraform && terraform output

# Test Lambda locally
aws lambda invoke --function-name NAME response.json
```

## Environment Variables

```bash
# Set environment
export ENVIRONMENT=sandbox  # or staging, production
export AWS_REGION=eu-west-1

# Enable debug logging
export LOG_LEVEL=0

# Skip AWS pager
export AWS_PAGER=""
```

## File Locations

- **Main Deployment:** `./scripts/deploy.sh`
- **Common Library:** `./scripts/lib/common.sh`
- **Documentation:** `./docs/`
- **CI/CD Workflows:** `./.github/workflows/`
- **Terraform:** `./terraform/`
- **Lambda Functions:** `./lambda/`
- **Frontend:** `./frontend/`

## Documentation

- **[README.md](README.md)** - Project overview
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Production deployment guide
- **[FINAL_REVIEW_SUMMARY.md](FINAL_REVIEW_SUMMARY.md)** - Automation summary
- **[docs/development/SCRIPTS_REFERENCE.md](docs/development/SCRIPTS_REFERENCE.md)** - Scripts documentation

## Help Commands

```bash
# Script help
./scripts/deploy.sh --help

# List all scripts
ls -l scripts/*.sh

# View common library functions
cat scripts/lib/common.sh | grep "^[a-z_]*() {"
```

## Success Criteria

✅ Deployment completes without errors  
✅ All smoke tests pass  
✅ API Gateway responds  
✅ AppSync endpoint accessible  
✅ Frontend loads successfully  
✅ Admin user can log in  
✅ CloudWatch logs show activity  

## Quick Links

- AWS Console: https://console.aws.amazon.com/
- GitHub Actions: https://github.com/YOUR-ORG/aws-serverless-task-manager/actions
- Documentation: `./docs/README.md`

## Support

- Deployment issues → [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)
- Script issues → [docs/development/SCRIPTS_REFERENCE.md](docs/development/SCRIPTS_REFERENCE.md)
- General issues → [docs/getting-started/TROUBLESHOOTING.md](docs/getting-started/TROUBLESHOOTING.md)

---

**Time to Deploy:** 15-20 minutes (full stack)  
**Last Updated:** February 12, 2026  
**Status:** ✅ Production Ready
