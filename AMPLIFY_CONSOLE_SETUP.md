# AWS Amplify Console Deployment Guide

This guide covers manual setup of AWS Amplify Hosting for the task manager frontend with Next.js SSR support in a monorepo structure.

## Why Manual Console Setup?

Terraform's AWS Amplify provider has limitations:
- ❌ No `app_root` parameter support (critical for monorepos)
- ❌ Limited framework detection in subdirectories
- ❌ SSR configuration issues with Next.js in `/frontend`

Manual Console setup provides:
- ✅ Built-in monorepo support with app_root
- ✅ Better Next.js SSR detection and optimization
- ✅ Visual configuration interface
- ✅ Real-time build logs and debugging

---

## Prerequisites

Before starting, ensure you have:
- ✅ GitHub repository: `https://github.com/Ayamigah16/aws-serverless-task-manager`
- ✅ Backend infrastructure deployed (Cognito, AppSync, DynamoDB)
- ✅ GitHub account with repo access
- ✅ AWS Console access

Get your backend configuration:
```bash
cd terraform
terraform output
```

Note these values:
- **Cognito User Pool ID:** `eu-west-1_UE7DtSgWR`
- **Cognito Client ID:** `okh3pgk9j011v7sq9nk6gicet`
- **AppSync Endpoint:** `https://5fjbcujvabdvxbcxfhjaffond4.appsync-api.eu-west-1.amazonaws.com/graphql`
- **AWS Region:** `eu-west-1`

---

## Step 1: Create New Amplify App

1. **Open AWS Amplify Console**
   - Navigate to: https://console.aws.amazon.com/amplify/
   - Select Region: **eu-west-1** (Ireland)

2. **Create New App**
   - Click **"New app"** → **"Host web app"**
   - Choose: **GitHub**
   - Click **"Connect to GitHub"**

3. **Authorize GitHub**
   - Sign in to GitHub if prompted
   - Click **"Authorize AWS Amplify"**
   - Select **"Only select repositories"**
   - Choose: `Ayamigah16/aws-serverless-task-manager`
   - Click **"Install & Authorize"**

---

## Step 2: Configure Repository

1. **Select Repository**
   - Repository: `Ayamigah16/aws-serverless-task-manager`
   - Branch: **main**
   - Check ☑ **"Connecting a monorepo? Pick a folder"**
   - Monorepo folder: **frontend**
   - Click **"Next"**

2. **Important: App root configuration**
   The monorepo folder setting (`frontend`) is CRITICAL for:
   - Next.js framework detection
   - SSR runtime selection
   - Correct build artifact location

---

## Step 3: Configure Build Settings

1. **App name**
   - Enter: `task-manager-frontend`

2 **Build and test settings**
   - Amplify should auto-detect **Next.js - SSR**
   - ✅ Verify it shows: "Next.js - SSR" (NOT "Next.js - Static")

3. **Build spec (amplify.yml)**
   - Keep the **existing amplify.yml** in your repository root
   - Amplify will automatically use it
   - ✅ Already configured with `baseDirectory: frontend`

4. **Click "Advanced settings"**

---

## Step 4: Configure Environment Variables

Add these environment variables (CRITICAL for app functionality):

| Variable Name | Value | Notes |
|--------------|-------|-------|
| `NEXT_PUBLIC_COGNITO_USER_POOL_ID` | `eu-west-1_UE7DtSgWR` | From terraform output |
| `NEXT_PUBLIC_USER_POOL_CLIENT_ID` | `okh3pgk9j011v7sq9nk6gicet` | From terraform output |
| `NEXT_PUBLIC_APPSYNC_ENDPOINT` | `https://5fjbcujvabdvxbcxfhjaffond4.appsync-api.eu-west-1.amazonaws.com/graphql` | From terraform output |
| `NEXT_PUBLIC_AWS_REGION` | `eu-west-1` | Your AWS region |

**How to add:**
1. Click **"+ Add environment variable"**
2. Enter variable name and value
3. Repeat for all 4 variables
4. Click **"Next"**

---

## Step 5: Review and Deploy

1. **Review Configuration**
   - ✅ Repository: `aws-serverless-task-manager`
   - ✅ Branch: `main`
   - ✅ Monorepo: `frontend`
   - ✅ Framework: Next.js - SSR
   - ✅ Environment variables: 4 configured

2. **Create App**
   - Click **"Save and deploy"**
   - Wait for initial deployment (3-5 minutes)

3. **Monitor Deployment**
   - Watch the build steps: Provision → Build → Deploy → Verify
   - Check build logs for errors
   - Look for: "✓ Generating static pages"

---

## Step 6: Configure Production Branch

After deployment completes:

1. **Set Branch to Production Stage**
   - Go to: **App settings** → **General**
   - Click **"Edit"** next to Branch settings
   - For **main** branch:
     - Stage: **Production**
     - ☑ Enable performance mode
   - Click **"Save"**

2. **Update Cognito Callback URLs**
   
   Get your new Amplify domain:
   ```bash
   # Your domain will be: https://main.XXXXX.amplifyapp.com
   ```

   Update Terraform configuration:
   ```bash
   cd terraform
   nano terraform.tfvars
   ```

   Update these lines:
   ```hcl
   cognito_callback_urls = [
     "http://localhost:3000",
     "https://main.YOUR_AMPLIFY_DOMAIN.amplifyapp.com"  # ← Update this
   ]
   cognito_logout_urls = [
     "http://localhost:3000",
     "https://main.YOUR_AMPLIFY_DOMAIN.amplifyapp.com"  # ← Update this
   ]
   ```

   Apply changes:
   ```bash
   terraform apply -auto-approve
   ```

---

## Step 7: Verify Deployment

1. **Check Build Status**
   - Build should show: **✅ Verified**
   - All steps (Provision, Build, Deploy, Verify) succeeded

2. **Test the Application**
   - Click the generated URL: `https://main.XXXXX.amplifyapp.com`
   - Should see the **login page** (NOT 404 or welcome screen)
   - Check browser dev tools Network tab for SSR:
     - Should see HTML with rendered content
     - NOT just empty div with client-side JavaScript load

3. **Verify SSR is Working**
   ```bash
   curl -I https://main.YOUR_AMPLIFY_DOMAIN.amplifyapp.com
   ```
   
   Check the response headers:
   - ✅ Should show: `server: Vercel` or `x-vercel-cache`
   - ❌ NOT: `server: AmazonS3` (that means static hosting)

---

## Step 8: Configure Auto-Deployments

1. **Enable Auto-Build**
   - Go to: **App settings** → **Build settings**
   - For **main** branch:
     - ☑ **Auto-build** enabled
   - Now every push to `main` triggers automatic deployment

2. **Configure Branch Builds (Optional)**
   - Go to: **App settings** → **Branch management**
   - Configure branch patterns for auto-build
   - Example: Auto-build on `feature/*` branches

---

## Troubleshooting

### Issue: 404 Error on Deployment URL

**Symptoms:**
- Build succeeds
- URL returns 404

**Causes:**
1. Monorepo folder not set to `frontend`
2. Framework detected as "Static" instead of "SSR"
3. Wrong baseDirectory in amplify.yml

**Fix:**
1. Go to: **App settings** → **General** → **Edit**
2. Under "Monorepo" section:
   - Set app root: **frontend**
3. Redeploy the branch

---

### Issue: Environment Variables Not Loading

**Symptoms:**
- Build succeeds
- App shows errors about missing Amplify configuration
- Console errors: "Amplify has not been configured"

**Fix:**
1. Go to: **App settings** → **Environment variables**
2. Verify all 4 variables are set:
   - `NEXT_PUBLIC_COGNITO_USER_POOL_ID`
   - `NEXT_PUBLIC_USER_POOL_CLIENT_ID`
   - `NEXT_PUBLIC_APPSYNC_ENDPOINT`
   - `NEXT_PUBLIC_AWS_REGION`
3. Redeploy: **main branch** → **Redeploy this version**

---

### Issue: Static Hosting Instead of SSR

**Symptoms:**
- HTTP header shows: `server: AmazonS3`
- Page returns 404 for routes

**Fix:**
1. Check Framework Detection:
   - Go to: **App settings** → **Build settings**
   - Should show: **Next.js - SSR** (NOT "Next.js")
2. If wrong framework:
   - Delete and recreate app
   - Ensure "Monorepo" is set during initial setup
3. Check `next.config.js`:
   - Should NOT have `output: 'standalone'` or `output: 'export'`

---

### Issue: Cognito Redirect Mismatch

**Symptoms:**
- Login succeeds but redirects to wrong URL
- Error: "redirect_uri_mismatch"

**Fix:**
1. Get current Amplify URL from console
2. Update Cognito configuration:
   ```bash
   cd terraform
   nano terraform.tfvars  # Update cognito_callback_urls
   terraform apply -auto-approve
   ```

---

## Monitoring and Logs

### Build Logs
- Go to: **Your App** → **main branch** → Latest build
- Click build ID to see detailed logs
- Useful for debugging build failures

### Runtime Logs
- SSR runtime logs: CloudWatch Logs
- Search for log group: `/aws/amplify/YOUR_APP_ID`
- Check for runtime errors

### Performance Monitoring
- Go to: **Monitoring**
- View metrics:
  - Request count
  - Error rate
  - Cache hit ratio (if performance mode enabled)

---

## Post-Deployment Tasks

### 1. Create Admin User
```bash
./scripts/create-admin.sh
```

- Follow prompts to create admin account
- Email must match allowed domains: `@amalitech.com` or `@amalitechtraining.org`
- Initial password requires: 8+ chars, uppercase, lowercase, number, special char
- You'll be prompted to change password on first login

### 2. Test Complete Workflow

1. **Authentication**
   - Visit your Amplify URL
   - Sign up with allowed email domain
   - Verify email
   - Log in

2. **Task Management**
   - Create a new project
   - Create tasks within project
   - Assign tasks to team members
   - Update task status

3. **Notifications**
   - Verify email notifications arrive
   - Check SNS subscriptions in AWS Console

---

## Cleanup (If Needed)

To remove Amplify deployment:

1. **In AWS Console:**
   - Go to: Amplify → Your App
   - Actions → Delete app
   - Type app name to confirm

2. **Keep Backend Running:**
   - Backend (Cognito, AppSync, DynamoDB, Lambda) stays intact
   - Only frontend hosting is removed

3. **To Remove Everything:**
   ```bash
   cd terraform
   terraform destroy -auto-approve
   ```

---

## Additional Resources

- [AWS Amplify Hosting Docs](https://docs.aws.amazon.com/amplify/latest/userguide/welcome.html)
- [Next.js SSR on Amplify](https://docs.aws.amazon.com/amplify/latest/userguide/server-side-rendering-amplify.html)
- [Monorepo Configuration](https://docs.aws.amazon.com/amplify/latest/userguide/monorepo-configuration.html)
- [Environment Variables](https://docs.aws.amazon.com/amplify/latest/userguide/environment-variables.html)

---

## Summary Checklist

Before considering deployment complete:

- [ ] Amplify app created and connected to GitHub
- [ ] Monorepo folder set to `frontend`
- [ ] Framework detected as "Next.js - SSR"
- [ ] All 4 environment variables configured
- [ ] Initial deployment succeeded
- [ ] Application loads (not 404)
- [ ] SSR verified (server-rendered HTML)
- [ ] Cognito callback URLs updated
- [ ] Admin user created
- [ ] Authentication tested
- [ ] Task creation tested
- [ ] Auto-build enabled
- [ ] Production branch stage set
- [ ] Performance mode enabled

---

**Need Help?**

Check build logs in Amplify Console or contact DevOps team.
