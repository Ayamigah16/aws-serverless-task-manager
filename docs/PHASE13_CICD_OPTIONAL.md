# Phase 13: CI/CD Pipeline (Optional Enhancement)

## Status: OPTIONAL ENHANCEMENT

This phase is an optional enhancement to add automated CI/CD pipeline for continuous deployment.

---

## Overview

Implement automated CI/CD pipeline using GitHub Actions to:
- Run tests on every push
- Deploy infrastructure on merge to main
- Deploy frontend automatically
- Run security scans
- Validate code quality

---

## Option 1: GitHub Actions

### Setup

Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd scripts
          npm install
      
      - name: Run tests
        run: |
          cd scripts
          npm test
      
      - name: Security scan
        run: |
          npm audit --audit-level=high

  terraform:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    needs: test
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-1
      
      - name: Terraform Init
        run: |
          cd terraform
          terraform init
      
      - name: Terraform Plan
        run: |
          cd terraform
          terraform plan
      
      - name: Terraform Apply
        if: github.event_name == 'push'
        run: |
          cd terraform
          terraform apply -auto-approve

  frontend:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    needs: terraform
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Build frontend
        run: |
          cd frontend
          npm install
          npm run build
      
      - name: Deploy to Amplify
        run: |
          # Deploy to AWS Amplify
          # Or upload to S3
          echo "Deploy frontend"
```

### GitHub Secrets

Add to repository secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `TERRAFORM_BACKEND_BUCKET`

---

## Option 2: AWS CodePipeline

### Setup

Create `buildspec.yml`:

```yaml
version: 0.2

phases:
  install:
    runtime-versions:
      nodejs: 18
    commands:
      - npm install -g terraform@1.5.0
  
  pre_build:
    commands:
      - cd scripts && npm install
      - cd ../terraform && terraform init
  
  build:
    commands:
      - cd terraform
      - terraform plan
      - terraform apply -auto-approve
  
  post_build:
    commands:
      - cd ../frontend
      - npm install
      - npm run build

artifacts:
  files:
    - '**/*'
  base-directory: frontend/build
```

### Create Pipeline

```bash
# Create CodePipeline
aws codepipeline create-pipeline --cli-input-json file://pipeline.json

# Create CodeBuild project
aws codebuild create-project --cli-input-json file://buildproject.json
```

---

## Option 3: GitLab CI

Create `.gitlab-ci.yml`:

```yaml
stages:
  - test
  - deploy

test:
  stage: test
  image: node:18
  script:
    - cd scripts
    - npm install
    - npm test

deploy:
  stage: deploy
  image: hashicorp/terraform:1.5.0
  only:
    - main
  script:
    - cd terraform
    - terraform init
    - terraform plan
    - terraform apply -auto-approve
```

---

## Security Scanning

### Add to CI Pipeline

```yaml
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    
    - name: Run tfsec
      uses: aquasecurity/tfsec-action@v1.0.0
      with:
        working_directory: terraform
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        directory: terraform
```

---

## Deployment Stages

### Multi-Environment

```yaml
deploy-dev:
  if: github.ref == 'refs/heads/develop'
  run: terraform apply -var-file=environments/dev.tfvars

deploy-prod:
  if: github.ref == 'refs/heads/main'
  run: terraform apply -var-file=environments/prod.tfvars
```

---

## Rollback Strategy

### Automatic Rollback

```yaml
rollback:
  if: failure()
  steps:
    - name: Rollback
      run: |
        cd terraform
        terraform destroy -target=module.api_gateway
        terraform apply
```

---

## Notifications

### Slack Integration

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Cost

**GitHub Actions:** Free for public repos, $0.008/minute for private  
**AWS CodePipeline:** $1/pipeline/month  
**GitLab CI:** Free tier available

---

## Implementation Steps

1. Choose CI/CD platform
2. Create workflow file
3. Configure secrets
4. Test pipeline
5. Enable branch protection
6. Set up notifications

---

## Benefits

✅ Automated testing  
✅ Consistent deployments  
✅ Faster feedback  
✅ Reduced human error  
✅ Security scanning  
✅ Audit trail  

---

## Status

**Phase 13:** Optional Enhancement  
**Recommended:** Implement after initial deployment  
**Priority:** Medium  
**Effort:** 1-2 days

---

**Note:** Core project (Phases 1-12) is complete and production-ready. This phase is an optional enhancement for automation.
