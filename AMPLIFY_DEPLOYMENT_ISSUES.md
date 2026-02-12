# Amplify Deployment Issues Analysis

## Summary
The Amplify deployment failed with **ERR_TOO_MANY_REDIRECTS** due to misconfigurations in both Terraform and amplify.yml that don't align with Next.js 14 SSR deployment requirements.

---

## 🔴 Critical Issues Found

### 1. **Wrong Artifacts Configuration in amplify.yml**

**Current (INCORRECT):**
```yaml
artifacts:
  baseDirectory: frontend/.next
  files:
    - '**/*'
```

**Problem:** 
- Points to `.next` directory only
- Next.js SSR apps need the entire application structure, not just the build output
- Missing `package.json`, `node_modules`, `public/`, and server files

**Correct Configuration:**
```yaml
artifacts:
  baseDirectory: frontend
  files:
    - '**/*'
```

---

### 2. **Incorrect Custom Routing Rules in Terraform**

**Current (INCORRECT):**
```terraform
custom_rule {
  source = "/<*>"
  status = "404"
  target = "/index.html"
}

custom_rule {
  source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|ttf|map|json|webp)$)([^.]+$)/>"
  status = "200"
  target = "/index.html"
}
```

**Problem:**
- These SPA-style redirects conflict with Next.js SSR routing
- Next.js has its own `_next/` routing and dynamic routes
- Causes redirect loops when pages try to load
- Redirects API routes and server-rendered pages to index.html

**Solution:**
**REMOVE these custom rules entirely** for Next.js SSR apps. Amplify automatically handles Next.js routing.

---

### 3. **Framework Specification Issue**

**Current:**
```terraform
framework = "Next.js - SSR"
```

**Problem:**
- AWS Amplify auto-detects Next.js from `package.json`
- Explicit framework specification can cause conflicts
- The value "Next.js - SSR" may not be the correct AWS Amplify framework identifier

**Solution:**
Either remove the `framework` attribute entirely (let Amplify auto-detect) or use the correct value:
```terraform
# Option 1: Remove framework attribute (RECOMMENDED)
# Let Amplify auto-detect from package.json

# Option 2: Use Amplify's exact framework value
framework = "Next.js - SSR"  # Verify this is the correct AWS value
```

---

### 4. **Missing Next.js Specific Build Configuration**

**Problem:**
The amplify.yml doesn't account for Next.js SSR hosting requirements:
- No standalone output configuration
- No explicit Node.js version specification
- Missing Next.js server startup configuration

**Recommended amplify.yml for Next.js SSR:**
```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - cd frontend
        - echo "Installing dependencies..."
        - npm ci --legacy-peer-deps
        - echo "Node version:"
        - node --version
        - echo "NPM version:"
        - npm --version
    build:
      commands:
        - echo "Environment variables check..."
        - |
          if [ -z "$NEXT_PUBLIC_COGNITO_USER_POOL_ID" ]; then
            echo "ERROR: Required environment variables not set"
            exit 1
          fi
        - echo "Building Next.js SSR application..."
        - npm run build
        - echo "Build completed successfully"
  artifacts:
    baseDirectory: frontend
    files:
      - '**/*'
  cache:
    paths:
      - frontend/node_modules/**/*
      - frontend/.next/cache/**/*
```

---

### 5. **Authentication Flow Issues (Secondary)**

**Location:** `frontend/lib/amplify-config.ts`, `frontend/app/page.tsx`, `frontend/app/login/page.tsx`

**Problem:**
- Used `identityPoolId` which wasn't needed (removed in fix)
- Home page used server-side `redirect()` causing immediate redirects
- Login page didn't check existing auth state before rendering

**Status:** ✅ Already fixed in commit `8d0ff80`

---

## 🔧 Recommended Fixes

### Fix 1: Update amplify.yml
```yaml
artifacts:
  baseDirectory: frontend  # Changed from frontend/.next
  files:
    - '**/*'
```

### Fix 2: Update Terraform modules/amplify/main.tf

**Remove the custom_rule blocks:**
```terraform
resource "aws_amplify_app" "frontend" {
  name        = var.app_name
  repository  = var.repository_url
  description = "Task Manager Frontend Application"
  platform    = "WEB"

  access_token = data.aws_secretsmanager_secret_version.github_token.secret_string
  build_spec   = file("${path.root}/../amplify.yml")

  environment_variables = {
    # ... existing vars ...
  }

  # REMOVE these custom_rule blocks for Next.js SSR
  # custom_rule {
  #   source = "/<*>"
  #   status = "404"
  #   target = "/index.html"
  # }

  enable_branch_auto_build    = var.enable_auto_build
  enable_branch_auto_deletion = true
  enable_auto_branch_creation = false
  iam_service_role_arn        = aws_iam_role.amplify.arn

  tags = merge(var.tags, {
    Environment = var.environment
    Application = "TaskManager"
    ManagedBy   = "Terraform"
  })
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = var.main_branch_name
  stage       = var.environment == "production" ? "PRODUCTION" : (
    var.environment == "staging" ? "BETA" : "DEVELOPMENT"
  )
  enable_auto_build           = true
  enable_pull_request_preview = var.enable_pr_preview

  # Remove explicit framework - let Amplify auto-detect
  # framework = "Next.js - SSR"

  tags = var.tags
}
```

---

## 📋 Deployment Checklist

- [ ] Update `amplify.yml` - change baseDirectory to `frontend`
- [ ] Update `terraform/modules/amplify/main.tf` - remove custom_rule blocks
- [ ] Update `terraform/modules/amplify/main.tf` - remove framework attribute from branches
- [ ] Commit and push changes to GitHub
- [ ] Run `terraform apply` to update Amplify app configuration
- [ ] Trigger new Amplify build
- [ ] Verify application loads without redirect loops
- [ ] Test authentication flow
- [ ] Test all routes and API connectivity

---

## 🎯 Root Cause Summary

The redirect loop occurred because:

1. **amplify.yml** served only the `.next` build directory without the full Next.js application structure
2. **Terraform custom rules** redirected all non-asset requests to `/index.html` (SPA pattern)
3. Next.js tried to render server-side routes but got redirected back to itself
4. Browser detected the infinite loop and showed `ERR_TOO_MANY_REDIRECTS`

The fix requires treating this as a **Next.js SSR application**, not a static SPA, which means:
- Serving the full application directory
- Removing custom routing rules
- Letting Next.js handle its own routing
- Ensuring the Node.js server can start properly

---

## 📚 AWS Amplify + Next.js SSR References

- [AWS Amplify Next.js SSR Documentation](https://docs.amplify.aws/guides/hosting/nextjs/q/platform/js/)
- [Next.js Deployment Best Practices](https://nextjs.org/docs/deployment)
- [Amplify Build Specification](https://docs.aws.amazon.com/amplify/latest/userguide/build-settings.html)
