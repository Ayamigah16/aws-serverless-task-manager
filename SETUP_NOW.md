# Quick Setup

## ✅ Backend Deployed

Your Terraform infrastructure is deployed with:
- API Gateway: `https://95jf4u1sa9.execute-api.eu-west-1.amazonaws.com/sandbox/tasks`
- User Pool: `eu-west-1_KalR0RFsK`
- Region: `eu-west-1`

## 🔧 Configure Frontend

### 1. Get Client ID
```bash
cd terraform
terraform output cognito_user_pool_client_id
```

### 2. Update .env.local
Edit `frontend/.env.local` and replace `YOUR_CLIENT_ID_HERE` with the value from step 1.

### 3. Start Development
```bash
cd frontend
npm run dev
```

Open http://localhost:3000

## 📝 Current Configuration

The `.env.local` file has been pre-configured with:
- ✅ API Gateway endpoint
- ✅ User Pool ID
- ✅ AWS Region
- ⚠️  Client ID (needs manual input)
- ⏳ AppSync (will be added when deployed)
- ⏳ S3 Bucket (will be added when deployed)

## 🎯 Next Steps

1. Get your Client ID from Terraform
2. Update `.env.local`
3. Run `npm run dev`
4. Login with your Cognito credentials

The app will work with the REST API (existing Lambda functions) immediately!
