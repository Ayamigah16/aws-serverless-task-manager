# Production Deployment Checklist

## Pre-Deployment Verification

### Infrastructure Readiness
- [ ] AWS credentials configured and tested
- [ ] Terraform state backend configured (S3 + DynamoDB)
- [ ] All required AWS services enabled in target region
- [ ] IAM roles and permissions reviewed
- [ ] Cost estimation reviewed and approved
- [ ] Backup strategy in place

### Code Quality
- [ ] All tests passing (unit, integration, e2e)
- [ ] Code review completed and approved
- [ ] Security scan completed (no critical issues)
- [ ] Linting passed (no errors)
- [ ] Dependencies updated and audited

### Configuration
- [ ] Environment variables configured
- [ ] Secrets stored in AWS Secrets Manager
- [ ] GitHub secrets configured for CI/CD
- [ ] Domain names and SSL certificates ready
- [ ] CORS origins configured correctly
- [ ] SES email addresses verified
- [ ] SNS subscriptions confirmed

### Documentation
- [ ] API documentation updated
- [ ] Architecture diagrams current
- [ ] Runbook updated
- [ ] Rollback procedure documented
- [ ] Change log updated

## Deployment Process

### Phase 1: Infrastructure (5-10 minutes)

```bash
# Deploy infrastructure
./scripts/deploy.sh --environment production --skip-lambdas --skip-frontend

# Or use CI/CD
# Push to main branch or trigger workflow manually
```

**Verification:**
- [ ] Terraform apply completed successfully
- [ ] No errors in Terraform output
- [ ] All resources created as expected
- [ ] API Gateway endpoint accessible
- [ ] AppSync endpoint accessible
- [ ] DynamoDB tables created
- [ ] Cognito User Pool created
- [ ] S3 buckets created

**Rollback:** `terraform destroy` or restore from backup

---

### Phase 2: Lambda Functions (3-5 minutes)

```bash
# Deploy Lambda functions
./scripts/deploy.sh --environment production --skip-infrastructure --skip-frontend

# Or deploy specific functions
aws lambda update-function-code \
  --function-name task-manager-production-task-api \
  --zip-file fileb://lambda/task-api/function.zip
```

**Verification:**
- [ ] All Lambda functions deployed
- [ ] Function versions updated
- [ ] No errors in deployment logs
- [ ] CloudWatch Logs groups created
- [ ] Lambda layer published

**Test:**
```bash
# Test Lambda invocation
aws lambda invoke \
  --function-name task-manager-production-task-api \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json
```

**Rollback:** Deploy previous function version or revert code

---

### Phase 3: Frontend (10-15 minutes)

```bash
# Configure Amplify
./scripts/setup-amplify.sh

# Trigger deployment via Amplify Console or GitHub
```

**Verification:**
- [ ] Amplify app configured
- [ ] Environment variables set
- [ ] Build completed successfully
- [ ] Deployment completed
- [ ] CloudFront distribution updated
- [ ] Frontend accessible via URL

**Rollback:** Redeploy previous Amplify version

---

### Phase 4: Post-Deployment

#### Smoke Tests
```bash
# Run automated smoke tests
./scripts/e2e-tests.sh --environment production

# Manual checks
curl https://api.production.taskmanager.com/health
curl https://app.production.taskmanager.com
```

**Verification:**
- [ ] API endpoints responding
- [ ] GraphQL queries working
- [ ] Authentication flow working
- [ ] Database queries executing
- [ ] File uploads working
- [ ] Notifications sending

#### Admin Setup
```bash
# Create admin user
./scripts/create-admin.sh
```

- [ ] Admin user created
- [ ] Admin can log in
- [ ] Admin has correct permissions

#### Monitoring Setup
- [ ] CloudWatch alarms configured
- [ ] Log aggregation working
- [ ] Error tracking setup (e.g., Sentry)
- [ ] Performance monitoring enabled
- [ ] Cost alerts configured

#### Data Migration (if applicable)
```bash
# Run data migration scripts
./scripts/migrate-data.sh --from staging --to production
```

- [ ] Data migration completed
- [ ] Data integrity verified
- [ ] No data loss
- [ ] Referential integrity maintained

---

## Automated Deployment

### Using CI/CD (Recommended)

**Full Deployment:**
```bash
# Push to main branch
git push origin main

# Or trigger manually via GitHub Actions
gh workflow run deploy.yml -f environment=production
```

**Component-Specific:**
```bash
# Infrastructure only
gh workflow run terraform-deploy.yml -f environment=production

# Lambdas only
gh workflow run lambda-deploy.yml -f environment=production

# Frontend only
gh workflow run frontend-deploy.yml -f environment=production
```

### Using Deployment Script

**Full Stack Deployment:**
```bash
./scripts/deploy.sh --environment production
```

**Selective Deployment:**
```bash
# Infrastructure only
./scripts/deploy.sh --environment production --infrastructure-only

# Lambdas only
./scripts/deploy.sh --environment production --lambdas-only

# Skip infrastructure
./scripts/deploy.sh --environment production --skip-infrastructure
```

---

## Post-Deployment Verification

### Functional Testing
- [ ] User registration works
- [ ] User login works
- [ ] Task CRUD operations work
- [ ] File uploads work
- [ ] Notifications sent
- [ ] Search functionality works
- [ ] Filters and sorting work

### Performance Testing
- [ ] Response times acceptable (< 200ms for API)
- [ ] No memory leaks in Lambda functions
- [ ] Database queries optimized
- [ ] CloudFront caching working
- [ ] S3 access optimized

### Security Testing
- [ ] Authentication required for protected routes
- [ ] CORS restrictions working
- [ ] SQL injection protection active
- [ ] XSS protection active
- [ ] CSRF tokens validated
- [ ] Rate limiting working
- [ ] Secrets not exposed in logs

### Monitoring & Alerts
- [ ] CloudWatch dashboards showing data
- [ ] Alarms triggering correctly
- [ ] Log aggregation working
- [ ] Error rates acceptable
- [ ] No unusual patterns in metrics

---

## Rollback Procedure

### Immediate Rollback (< 5 minutes)

**Lambda Functions:**
```bash
# Revert to previous version
aws lambda update-function-code \
  --function-name task-manager-production-task-api \
  --s3-bucket my-lambda-versions \
  --s3-key task-api-v1.0.0.zip
```

**Frontend:**
```bash
# Redeploy previous Amplify version
aws amplify start-job \
  --app-id <app-id> \
  --branch-name main \
  --job-type RELEASE \
  --job-id <previous-job-id>
```

### Full Rollback (10-15 minutes)

**Infrastructure:**
```bash
# Revert Terraform to previous state
cd terraform
git checkout <previous-commit>
terraform apply
```

**Database:**
```bash
# Restore from snapshot (if needed)
aws dynamodb restore-table-from-backup \
  --target-table-name task-manager-production-tasks \
  --backup-arn <backup-arn>
```

---

## Troubleshooting

### Common Issues

**Terraform Errors:**
- Check AWS credentials
- Verify resource quotas
- Review Terraform state conflicts
- Check for resource naming conflicts

**Lambda Deployment Failures:**
- Verify function package size (< 50MB)
- Check IAM role permissions
- Review Lambda execution role
- Verify environment variables

**Frontend Build Failures:**
- Check environment variables in Amplify
- Verify Node.js version
- Review build logs in Amplify Console
- Check for dependency conflicts

**API Errors:**
- Review CloudWatch Logs
- Check API Gateway configuration
- Verify Lambda function permissions
- Test with AWS CLI/Console

---

## Success Criteria

- [ ] All deployment phases completed successfully
- [ ] All smoke tests passing
- [ ] No critical errors in logs
- [ ] Performance metrics within acceptable range
- [ ] Security scans showing no critical issues
- [ ] Monitoring & alerting operational
- [ ] Documentation updated
- [ ] Team notified of deployment
- [ ] Rollback procedure tested and ready

---

## Environment-Specific Notes

### Sandbox
- Auto-deploys on push to `develop` branch
- Used for development and testing
- Data can be reset at any time
- Lower resource limits

### Staging
- Mirrors production configuration
- Used for pre-production testing
- Manual approval required for deployment
- Integrated with production-like data

### Production
- Requires approval from multiple reviewers
- Deployed from `main` branch only
- Full backup before deployment
- Blue-green deployment recommended
- Zero-downtime deployment required

---

## Contact & Support

**Deployment Team:**
- DevOps Lead: [Contact Info]
- Backend Lead: [Contact Info]
- Frontend Lead: [Contact Info]

**Escalation:**
- On-call engineer: [Contact Info]
- Engineering Manager: [Contact Info]

**Resources:**
- Runbook: [Link]
- Architecture Docs: [docs/architecture/](../docs/architecture/)
- Troubleshooting Guide: [docs/getting-started/TROUBLESHOOTING.md](../docs/getting-started/TROUBLESHOOTING.md)

---

**Last Updated:** February 12, 2026  
**Version:** 2.0  
**Status:** ✅ Production Ready
