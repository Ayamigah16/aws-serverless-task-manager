# Production Readiness Checklist

## Pre-Deployment

### Infrastructure
- [ ] AWS account configured
- [ ] AWS CLI installed and configured
- [ ] Terraform v1.5.0+ installed
- [ ] Node.js v18+ installed
- [ ] Git repository up to date

### Configuration
- [ ] `terraform/terraform.tfvars` reviewed
- [ ] `admin_email` set
- [ ] `ses_sender_email` set
- [ ] `allowed_email_domains` verified
- [ ] `cognito_callback_urls` updated for production
- [ ] `cognito_logout_urls` updated for production

### Lambda Functions
- [ ] All Lambda functions built (`./scripts/build-lambdas.sh`)
- [ ] Lambda layer built
- [ ] Function.zip files exist for all functions

### Frontend
- [ ] Frontend built (`npm run build`)
- [ ] Environment variables configured
- [ ] API URL placeholder ready

---

## Deployment

### Step 1: Initialize Terraform
```bash
cd terraform
terraform init
```
- [ ] Terraform initialized successfully
- [ ] Backend configured
- [ ] Providers downloaded

### Step 2: Plan Deployment
```bash
terraform plan
```
- [ ] Plan reviewed
- [ ] Expected resources verified
- [ ] No errors in plan

### Step 3: Deploy Infrastructure
```bash
terraform apply
```
- [ ] Deployment successful
- [ ] All resources created
- [ ] No errors

### Step 4: Capture Outputs
```bash
terraform output > outputs.txt
```
- [ ] Cognito User Pool ID captured
- [ ] Cognito Client ID captured
- [ ] Cognito Domain captured
- [ ] API Gateway URL captured
- [ ] DynamoDB Table Name captured
- [ ] Region captured

---

## Post-Deployment Validation

### Cognito
- [ ] User Pool exists
- [ ] User Pool Client configured
- [ ] Hosted UI domain accessible
- [ ] Admin and Member groups created
- [ ] Pre Sign-Up Lambda attached

### API Gateway
- [ ] REST API created
- [ ] Cognito Authorizer configured
- [ ] CORS enabled
- [ ] Throttling configured
- [ ] CloudWatch logging enabled

### Lambda
- [ ] All 3 Lambda functions deployed
- [ ] Lambda layer attached
- [ ] Environment variables set
- [ ] CloudWatch log groups created
- [ ] X-Ray tracing enabled

### DynamoDB
- [ ] Table created
- [ ] GSI1 and GSI2 created
- [ ] Encryption enabled
- [ ] PITR enabled
- [ ] On-demand billing mode

### EventBridge
- [ ] Event bus created
- [ ] 3 event rules created
- [ ] Lambda targets configured

### SES
- [ ] Email identity created
- [ ] Email verification pending/complete

### CloudWatch
- [ ] Log groups created
- [ ] Alarms created
- [ ] Metrics visible

---

## Functional Testing

### Authentication
- [ ] Sign up with valid domain succeeds
- [ ] Sign up with invalid domain fails
- [ ] Email verification works
- [ ] Sign in after verification succeeds
- [ ] JWT token generated

### RBAC
- [ ] Admin can create task
- [ ] Member cannot create task (403)
- [ ] Admin can assign task
- [ ] Member can update status
- [ ] Member cannot close task (403)

### API Endpoints
- [ ] POST /tasks works (admin)
- [ ] GET /tasks works
- [ ] PUT /tasks/{id} works (admin)
- [ ] POST /tasks/{id}/assign works (admin)
- [ ] PUT /tasks/{id}/status works (member)
- [ ] POST /tasks/{id}/close works (admin)

### Notifications
- [ ] Task assignment sends email
- [ ] Status update sends email
- [ ] Task close sends email
- [ ] Deactivated users filtered

### Frontend
- [ ] Frontend deployed
- [ ] Can access application
- [ ] Sign in works
- [ ] Dashboard loads
- [ ] Can create task (admin)
- [ ] Can view tasks
- [ ] Can update status

---

## Security Validation

- [ ] Invalid JWT rejected (401)
- [ ] Missing JWT rejected (401)
- [ ] RBAC enforced (403)
- [ ] CORS works from frontend
- [ ] Throttling active
- [ ] CloudWatch logs show activity
- [ ] No secrets in logs
- [ ] Encryption at rest verified
- [ ] HTTPS only

---

## Performance Validation

- [ ] API response time < 500ms (p95)
- [ ] Lambda cold start < 1s
- [ ] No DynamoDB throttling
- [ ] No Lambda throttling
- [ ] CloudWatch metrics visible

---

## Monitoring Validation

- [ ] CloudWatch logs visible
- [ ] CloudWatch metrics updating
- [ ] CloudWatch alarms created
- [ ] X-Ray traces visible
- [ ] Service map shows components

---

## Documentation Validation

- [ ] README.md accurate
- [ ] API documentation complete
- [ ] User guides available
- [ ] Troubleshooting guide available
- [ ] Deployment guides accurate

---

## Final Checks

### Cost
- [ ] Billing alerts configured
- [ ] Cost Explorer reviewed
- [ ] Estimated monthly cost acceptable

### Backup
- [ ] DynamoDB PITR enabled
- [ ] Terraform state backed up
- [ ] Documentation backed up

### Support
- [ ] Support contacts documented
- [ ] Escalation path defined
- [ ] Monitoring alerts configured

### Compliance
- [ ] Security controls documented
- [ ] RBAC implemented
- [ ] Audit logging enabled
- [ ] Data encryption verified

---

## Sign-Off

### Technical Lead
- [ ] Infrastructure validated
- [ ] Security approved
- [ ] Performance acceptable
- [ ] Monitoring configured

**Signature:** ________________  
**Date:** ________________

### Project Manager
- [ ] All requirements met
- [ ] Documentation complete
- [ ] Budget approved
- [ ] Timeline met

**Signature:** ________________  
**Date:** ________________

### Security Officer
- [ ] Security controls verified
- [ ] Compliance requirements met
- [ ] Audit logging enabled
- [ ] Encryption verified

**Signature:** ________________  
**Date:** ________________

---

## Production Go-Live

- [ ] All checklist items complete
- [ ] All sign-offs obtained
- [ ] Rollback plan documented
- [ ] Support team briefed
- [ ] Users notified

**Go-Live Date:** ________________  
**Go-Live Time:** ________________

---

## Post Go-Live

### Day 1
- [ ] Monitor CloudWatch logs
- [ ] Check CloudWatch alarms
- [ ] Verify user sign-ups
- [ ] Monitor API usage
- [ ] Check error rates

### Week 1
- [ ] Review CloudWatch metrics
- [ ] Analyze user feedback
- [ ] Check cost actuals vs estimates
- [ ] Review security logs
- [ ] Performance optimization if needed

### Month 1
- [ ] Monthly cost review
- [ ] Security audit
- [ ] Performance review
- [ ] User satisfaction survey
- [ ] Documentation updates

---

**Status:** Ready for Production Deployment
