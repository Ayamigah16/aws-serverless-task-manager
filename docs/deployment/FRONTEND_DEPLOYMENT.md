# Frontend Deployment Guide

## Option 1: AWS Amplify Hosting (Recommended)

### Prerequisites
- AWS account
- GitHub repository (optional for CI/CD)
- Frontend built locally

### Manual Deployment

#### Step 1: Install Amplify CLI
```bash
npm install -g @aws-amplify/cli
```

#### Step 2: Configure Amplify
```bash
cd frontend
amplify init
```

Follow prompts:
- Project name: task-manager-frontend
- Environment: production
- Default editor: (your choice)
- App type: javascript
- Framework: react
- Source directory: src
- Distribution directory: build
- Build command: npm run build
- Start command: npm start

#### Step 3: Add Hosting
```bash
amplify add hosting
```

Choose:
- Hosting with Amplify Console (Managed hosting with CI/CD)
- Manual deployment

#### Step 4: Build and Deploy
```bash
npm run build
amplify publish
```

### CI/CD Deployment

#### Step 1: Connect Repository
1. Go to AWS Amplify Console
2. Click "New app" → "Host web app"
3. Connect GitHub/GitLab/Bitbucket
4. Select repository and branch
5. Configure build settings

#### Step 2: Build Settings
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: build
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

#### Step 3: Environment Variables
Add in Amplify Console:
- REACT_APP_USER_POOL_ID
- REACT_APP_USER_POOL_CLIENT_ID
- REACT_APP_COGNITO_DOMAIN
- REACT_APP_API_URL

#### Step 4: Deploy
- Push to connected branch
- Amplify automatically builds and deploys

---

## Option 2: S3 + CloudFront

### Step 1: Create S3 Bucket
```bash
aws s3 mb s3://task-manager-frontend
aws s3 website s3://task-manager-frontend --index-document index.html
```

### Step 2: Build Frontend
```bash
cd frontend
npm run build
```

### Step 3: Upload to S3
```bash
aws s3 sync build/ s3://task-manager-frontend --delete
```

### Step 4: Create CloudFront Distribution
```bash
aws cloudfront create-distribution \
  --origin-domain-name task-manager-frontend.s3.amazonaws.com \
  --default-root-object index.html
```

### Step 5: Update DNS (Optional)
Point custom domain to CloudFront distribution.

---

## Option 3: Local Development

### Run Locally
```bash
cd frontend
npm install
npm start
```

Access at http://localhost:3000

---

## Configuration

### Update .env
```env
REACT_APP_USER_POOL_ID=<from terraform output>
REACT_APP_USER_POOL_CLIENT_ID=<from terraform output>
REACT_APP_COGNITO_DOMAIN=<from terraform output>
REACT_APP_API_URL=<from terraform output>
```

### Update Cognito Callback URLs
In `terraform/terraform.tfvars`:
```hcl
cognito_callback_urls = [
  "http://localhost:3000",
  "https://your-amplify-domain.amplifyapp.com"
]

cognito_logout_urls = [
  "http://localhost:3000",
  "https://your-amplify-domain.amplifyapp.com"
]
```

Then redeploy:
```bash
cd terraform
terraform apply
```

---

## Verification

1. Access frontend URL
2. Click "Sign in"
3. Redirected to Cognito Hosted UI
4. Sign in with test user
5. Redirected back to app
6. Dashboard loads with tasks

---

## Troubleshooting

**Redirect loop:**
- Verify callback URLs match in Cognito and frontend
- Check REACT_APP_COGNITO_DOMAIN is correct

**API errors:**
- Verify REACT_APP_API_URL is correct
- Check CORS enabled on API Gateway
- Verify JWT token in requests

**Build fails:**
- Check Node.js version (18+)
- Clear node_modules and reinstall
- Check for syntax errors

---

**Recommended:** AWS Amplify Hosting for automatic CI/CD and HTTPS
