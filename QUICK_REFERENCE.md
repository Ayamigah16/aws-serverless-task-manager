# Quick Reference Guide

## 🚀 Common Commands

### Git Commands
```bash
# Initialize and first commit
git add .
git commit -m "Phase 1: Project setup and foundation"
git branch -M main
git remote add origin <repository-url>
git push -u origin main

# Daily workflow
git status
git add .
git commit -m "Description of changes"
git push
```

### AWS CLI Commands
```bash
# Verify access
aws sts get-caller-identity

# List resources
aws lambda list-functions
aws dynamodb list-tables
aws apigateway get-rest-apis
aws cognito-idp list-user-pools --max-results 10

# View logs
aws logs tail /aws/lambda/function-name --follow
```

### Terraform Commands
```bash
# Initialize
cd terraform
terraform init

# Validate
terraform validate
terraform fmt -recursive

# Plan and apply
terraform plan
terraform apply
terraform apply -auto-approve

# Destroy
terraform destroy

# State management
terraform state list
terraform state show <resource>
```

### Lambda Development
```bash
# Install dependencies
cd lambda/task-api
npm install

# Run tests
npm test
npm run test:coverage

# Package for deployment
zip -r function.zip .
```

### Frontend Development
```bash
# Install and run
cd frontend
npm install
npm start

# Build
npm run build

# Test
npm test
npm run lint
```

## 📁 Important File Locations

| File | Location | Purpose |
|------|----------|---------|
| Main README | `/README.md` | Project overview |
| Security Policy | `/SECURITY.md` | Security guidelines |
| TODO Tracker | `/TODO.md` | Project progress |
| Dev Setup | `/docs/DEVELOPMENT_SETUP.md` | Setup instructions |
| AWS Prep | `/docs/AWS_ACCOUNT_PREPARATION.md` | AWS configuration |
| Terraform Vars | `/terraform/environments/sandbox/terraform.tfvars` | Config values |
| Git Ignore | `/.gitignore` | Excluded files |

## 🔑 Environment Variables

### Terraform
```bash
export AWS_REGION=us-east-1
export AWS_DEFAULT_REGION=us-east-1
export TF_VAR_environment=sandbox
```

### Frontend
```bash
export REACT_APP_API_URL=https://api.example.com
export REACT_APP_REGION=us-east-1
```

## 📊 Project Status Check

```bash
# Check TODO status
cat TODO.md | grep -E "^\- \[x\]" | wc -l  # Completed
cat TODO.md | grep -E "^\- \[ \]" | wc -l  # Remaining

# Check Git status
git status
git log --oneline -10

# Check AWS resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=task-manager
```

## 🐛 Troubleshooting

### AWS Access Issues
```bash
# Refresh credentials
aws configure
aws sts get-caller-identity

# Check region
echo $AWS_REGION
```

### Terraform Issues
```bash
# Clear cache
rm -rf .terraform
terraform init

# Unlock state
terraform force-unlock <LOCK_ID>
```

### Lambda Issues
```bash
# Check logs
aws logs tail /aws/lambda/function-name --follow

# Test locally
sam local invoke FunctionName -e event.json
```

## 📞 Quick Links

- [AWS Console](https://console.aws.amazon.com)
- [Terraform Registry](https://registry.terraform.io)
- [AWS Documentation](https://docs.aws.amazon.com)
- [React Documentation](https://react.dev)

## 🎯 Phase Checklist

- [x] Phase 1: Project Setup ✅
- [ ] Phase 2: Terraform Foundation
- [ ] Phase 3: Authentication
- [ ] Phase 4: Database
- [ ] Phase 5: API & Lambda
- [ ] Phase 6: Notifications
- [ ] Phase 7: Frontend
- [ ] Phase 8: Security
- [ ] Phase 9: Monitoring
- [ ] Phase 10: Testing
- [ ] Phase 11: Documentation
- [ ] Phase 12: Deployment

---

**Keep this file handy for quick reference!**
