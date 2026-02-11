# AWS Amplify Deployment - Quick Start

## ✅ Environment Variables Created

Your `frontend/.env.local` has been created with:
```
NEXT_PUBLIC_USER_POOL_ID=eu-west-1_FfAVO3yNz
NEXT_PUBLIC_USER_POOL_CLIENT_ID=2f0i4se7ksrif4vot3tkp7g1jk
NEXT_PUBLIC_APPSYNC_URL=https://4yfcosstwzc4zor2pakty7so4y.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_AWS_REGION=eu-west-1
```

## 🚀 Deploy to AWS Amplify (via Console)

### Step 1: Test Locally
```bash
cd frontend
npm install
npm run dev
```
Visit http://localhost:3000 and verify it works.

### Step 2: Push to GitHub
```bash
git add .
git commit -m "Ready for Amplify deployment"
git push origin main
```

### Step 3: Deploy via Amplify Console

1. **Open Amplify Console**
   - Go to: https://console.aws.amazon.com/amplify
   - Click **New app** → **Host web app**

2. **Connect Repository**
   - Select **GitHub**
   - Authorize AWS Amplify
   - Choose repository: `aws-serverless-task-manager`
   - Choose branch: `main`
   - Click **Next**

3. **Configure Build Settings**
   - App name: `task-manager-frontend`
   - Build settings will auto-detect `amplify.yml`
   - Click **Advanced settings**

4. **Add Environment Variables**
   ```
   NEXT_PUBLIC_USER_POOL_ID = eu-west-1_FfAVO3yNz
   NEXT_PUBLIC_USER_POOL_CLIENT_ID = 2f0i4se7ksrif4vot3tkp7g1jk
   NEXT_PUBLIC_APPSYNC_URL = https://4yfcosstwzc4zor2pakty7so4y.appsync-api.eu-west-1.amazonaws.com/graphql
   NEXT_PUBLIC_AWS_REGION = eu-west-1
   ```

5. **Review and Deploy**
   - Click **Save and deploy**
   - Wait 5-10 minutes for build

6. **Get Your URL**
   - After deployment, you'll get: `https://main.xxxxx.amplifyapp.com`
   - Copy this URL

### Step 4: Update Cognito Callback URLs

```bash
cd terraform

# Edit terraform.tfvars - add your Amplify URL
nano terraform.tfvars
```

Add your Amplify URL to:
```hcl
cognito_callback_urls = [
  "http://localhost:3000",
  "https://main.xxxxx.amplifyapp.com"  # Your Amplify URL
]

cognito_logout_urls = [
  "http://localhost:3000",
  "https://main.xxxxx.amplifyapp.com"  # Your Amplify URL
]
```

Apply changes:
```bash
terraform apply -auto-approve
```

### Step 5: Test Deployment

1. Visit your Amplify URL
2. Click **Sign In**
3. Should redirect to Cognito
4. Sign in with your user
5. Should redirect back to dashboard

## 🎉 Done!

Your app is now live at: `https://main.xxxxx.amplifyapp.com`

## 📝 Notes

- **Auto-deploy**: Every push to `main` triggers automatic deployment
- **Preview branches**: Create feature branches for testing
- **Custom domain**: Add in Amplify Console → Domain management
- **Monitoring**: View logs in Amplify Console → Build history

## 🐛 Troubleshooting

**Build fails:**
- Check build logs in Amplify Console
- Verify all 4 environment variables are set
- Ensure Node.js version is 18+ (set in Amplify build settings)

**Redirect loop:**
- Verify Cognito callback URLs include your Amplify URL
- Check environment variables are correct

**Blank page:**
- Check browser console for errors
- Verify AppSync URL is accessible
- Check user is authenticated
