# Deploy Frontend to AWS Amplify

## Step 1: Initialize Amplify

```bash
cd frontend
amplify init
```

Answer prompts:
- Project name: `taskmanager`
- Environment: `dev`
- Default editor: (your choice)
- App type: `javascript`
- Framework: `react`
- Source directory: `src`
- Distribution directory: `.next`
- Build command: `npm run build`
- Start command: `npm run dev`
- Use AWS profile: `Yes` → select your profile

## Step 2: Add Hosting

```bash
cd frontend
amplify add hosting
```

Choose:
- **Hosting with Amplify Console** (Managed hosting with CI/CD)
- **Manual deployment**

## Step 2: Build Application

```bash
npm run build
```

## Step 3: Publish to Amplify

```bash
amplify publish
```

This will:
- Upload build artifacts to Amplify
- Provide your app URL: `https://dev.xxxxx.amplifyapp.com`

## Step 4: Update Cognito Callback URLs

After getting your Amplify URL, update Cognito:

```bash
cd ../terraform
nano terraform.tfvars
```

Add your Amplify URL:
```hcl
cognito_callback_urls = [
  "http://localhost:3000",
  "https://dev.xxxxx.amplifyapp.com"  # Your Amplify URL
]

cognito_logout_urls = [
  "http://localhost:3000",
  "https://dev.xxxxx.amplifyapp.com"  # Your Amplify URL
]
```

Apply:
```bash
terraform apply -auto-approve
```

## Step 5: Test

1. Visit your Amplify URL
2. Click **Sign In**
3. Should redirect to Cognito
4. Sign in with your user
5. Should redirect back to dashboard

## Update Deployment

```bash
cd frontend
npm run build
amplify publish
```

## View in Console

```bash
amplify console
```

Or visit: https://console.aws.amazon.com/amplify

## Useful Commands

```bash
# Check status
amplify status

# View logs
amplify console

# Delete hosting
amplify remove hosting
```
