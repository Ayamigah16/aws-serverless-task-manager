# Amplify Deployment - Next Steps

## ✅ Current Status

Amplify initialized successfully!
- Environment: dev
- App ID: d1zvi0bu3o5w29
- Region: eu-west-1

---

## Next Steps

### Step 1: Add Hosting
```bash
cd frontend
amplify add hosting
```

**Choose:**
- Hosting with Amplify Console (Managed hosting with CI/CD)
- Manual deployment

### Step 2: Configure Environment Variables

Before publishing, set environment variables in `.env`:

```bash
# Get values from Terraform
cd ../terraform
terraform output

# Update frontend/.env
cd ../frontend
nano .env
```

Add:
```env
REACT_APP_USER_POOL_ID=<from terraform output>
REACT_APP_USER_POOL_CLIENT_ID=<from terraform output>
REACT_APP_COGNITO_DOMAIN=<from terraform output>
REACT_APP_API_URL=<from terraform output>
```

### Step 3: Build and Publish
```bash
npm run build
amplify publish
```

This will:
1. Build the React app
2. Upload to Amplify hosting
3. Provide a URL (e.g., https://dev.d1zvi0bu3o5w29.amplifyapp.com)

### Step 4: Update Cognito Callback URLs

After getting your Amplify URL, update Cognito:

```bash
cd ../terraform
nano terraform.tfvars
```

Add your Amplify URL:
```hcl
cognito_callback_urls = [
  "http://localhost:3000",
  "https://dev.d1zvi0bu3o5w29.amplifyapp.com"
]

cognito_logout_urls = [
  "http://localhost:3000",
  "https://dev.d1zvi0bu3o5w29.amplifyapp.com"
]
```

Apply changes:
```bash
terraform apply
```

### Step 5: Test Deployment

1. Open Amplify URL: https://dev.d1zvi0bu3o5w29.amplifyapp.com
2. Click "Sign in"
3. Should redirect to Cognito Hosted UI
4. Sign in with test user
5. Should redirect back to app
6. Dashboard should load

---

## Amplify Console

Access your app in AWS Console:
```
https://eu-west-1.console.aws.amazon.com/amplify/home?region=eu-west-1#/d1zvi0bu3o5w29
```

From console you can:
- View deployment status
- Configure custom domain
- Set up CI/CD from Git
- Add environment variables
- View build logs

---

## Useful Commands

```bash
# Check status
amplify status

# View console
amplify console

# Publish updates
amplify publish

# Delete hosting
amplify remove hosting

# Delete entire Amplify project
amplify delete
```

---

## CI/CD Setup (Optional)

To enable automatic deployments from Git:

1. Go to Amplify Console
2. Click "Connect repository"
3. Choose GitHub/GitLab/Bitbucket
4. Select repository and branch
5. Configure build settings
6. Every push will auto-deploy

---

## Custom Domain (Optional)

1. Go to Amplify Console
2. Click "Domain management"
3. Add domain
4. Follow DNS configuration steps
5. SSL certificate auto-provisioned

---

## Troubleshooting

**Build fails:**
```bash
# Check build logs in Amplify Console
amplify console

# Or rebuild locally
npm run build
```

**Environment variables not working:**
- Add them in Amplify Console → Environment variables
- Redeploy: `amplify publish`

**Redirect issues:**
- Verify callback URLs in Cognito match Amplify URL
- Check `.env` file has correct values

---

## Success Criteria

✅ Amplify hosting added  
✅ Frontend built successfully  
✅ Published to Amplify URL  
✅ Cognito callback URLs updated  
✅ Can sign in via Hosted UI  
✅ Dashboard loads with data  

---

**Your Amplify App:** https://dev.d1zvi0bu3o5w29.amplifyapp.com (after publish)
