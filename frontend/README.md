# Task Manager Frontend

React application with AWS Amplify authentication and API integration.

## Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env
```

Edit `.env` with your AWS resources (from Terraform outputs):
- `REACT_APP_USER_POOL_ID`: Cognito User Pool ID
- `REACT_APP_USER_POOL_CLIENT_ID`: Cognito Client ID
- `REACT_APP_COGNITO_DOMAIN`: Cognito domain
- `REACT_APP_API_URL`: API Gateway URL

### 3. Run Development Server
```bash
npm start
```

Open [http://localhost:3000](http://localhost:3000)

## Features

### Authentication
- Cognito Hosted UI integration
- Email verification required
- Domain restrictions enforced
- JWT token management

### Admin Features
- Create tasks
- Update tasks
- Assign tasks
- Close tasks
- View all tasks

### Member Features
- View assigned tasks
- Update task status
- Receive notifications

## Project Structure

```
src/
├── components/
│   ├── Header.js          - Navigation header
│   ├── Dashboard.js       - Task statistics
│   ├── TaskList.js        - Task list with actions
│   └── CreateTask.js      - Task creation form (Admin)
├── contexts/
│   └── AuthContext.js     - Authentication state
├── services/
│   └── taskService.js     - API calls
├── aws-config.js          - Amplify configuration
├── App.js                 - Main app component
└── index.js               - Entry point
```

## Build for Production

```bash
npm run build
```

Deploy the `build/` directory to AWS Amplify or S3 + CloudFront.

## Environment Variables

| Variable | Description |
|----------|-------------|
| REACT_APP_REGION | AWS region |
| REACT_APP_USER_POOL_ID | Cognito User Pool ID |
| REACT_APP_USER_POOL_CLIENT_ID | Cognito Client ID |
| REACT_APP_COGNITO_DOMAIN | Cognito domain |
| REACT_APP_API_URL | API Gateway endpoint |
