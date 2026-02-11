# Complete Integration Guide

## System Architecture

**Backend (Lambda + API Gateway)**
- REST API endpoints at `/tasks`, `/users`, `/tasks/{id}/status`, `/tasks/{id}/assign`, `/tasks/{id}/close`
- Cognito authentication with JWT tokens
- DynamoDB single-table design
- EventBridge for notifications
- SES for email notifications

**Frontend (Next.js 14 + TypeScript)**
- REST API integration via AWS Amplify
- Real-time data with React Query
- Responsive UI with Tailwind CSS + shadcn/ui
- Role-based access control (Admin/Member)

## Quick Start

### 1. Deploy Backend
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. Verify SES Email
```bash
cd ..
./scripts/verify-ses-email.sh
# Enter your email and click verification link
```

### 3. Create Admin User
```bash
./scripts/create-admin.sh
# Follow prompts to create admin account
```

### 4. Configure Frontend
```bash
cd frontend
npm install
npm run dev
```

### 5. Access Application
- Open http://localhost:3000
- Sign up with @amalitech.com or @amalitechtraining.org email
- Admin users can access full features

## API Endpoints

### Tasks
- `GET /tasks` - List all tasks (admin) or assigned tasks (member)
- `POST /tasks` - Create task (admin only)
- `GET /tasks/{id}` - Get task details
- `PUT /tasks/{id}` - Update task (admin only)
- `PUT /tasks/{id}/status` - Update status (assigned users)
- `POST /tasks/{id}/assign` - Assign task (admin only)
- `POST /tasks/{id}/close` - Close task (admin only)
- `DELETE /tasks/{id}` - Delete task (admin only)

### Users
- `GET /users` - List all users (admin only)

## Frontend Pages

### Available Routes
- `/` - Redirects to dashboard
- `/dashboard` - Dashboard with metrics (uses REST API)
- `/tasks` - Task list view (simplified)
- `/tasks/rest` - Full task management (REST API with all features)
- `/login` - Cognito authentication
- `/signup` - User registration

### Key Features
1. **Dashboard** (`/dashboard`)
   - Real-time task metrics
   - Status breakdown (Open, In Progress, Completed)
   - Total task count
   - Link to full task management

2. **Task Management** (`/tasks/rest`)
   - View all tasks (admin) or assigned tasks (member)
   - Update task status
   - Assign tasks to users (admin)
   - Close tasks (admin)
   - Real-time updates with React Query

3. **Authentication**
   - Cognito-based login/signup
   - Email domain validation
   - Auto-confirm for allowed domains
   - JWT token management

## Role-Based Access Control

### Admin Users
- Create tasks
- Update any task
- Assign tasks to users
- Close tasks
- Delete tasks
- View all tasks
- List all users

### Member Users
- View assigned tasks only
- Update status of assigned tasks
- Cannot create, assign, or close tasks

## Environment Variables

Frontend `.env.local`:
```env
NEXT_PUBLIC_USER_POOL_ID=eu-west-1_KalR0RFsK
NEXT_PUBLIC_USER_POOL_CLIENT_ID=71sejofpdooh1bm67likfc9jdo
NEXT_PUBLIC_APPSYNC_ENDPOINT=https://se6e27yquve37kqcxrpjtymi3q.appsync-api.eu-west-1.amazonaws.com/graphql
NEXT_PUBLIC_API_ENDPOINT=https://95jf4u1sa9.execute-api.eu-west-1.amazonaws.com/sandbox/tasks
NEXT_PUBLIC_S3_BUCKET=task-manager-sandbox-attachments
NEXT_PUBLIC_AWS_REGION=eu-west-1
```

## Testing the Integration

### 1. Create Admin User
```bash
./scripts/create-admin.sh
```

### 2. Create Member User
- Sign up at http://localhost:3000/signup
- Use @amalitech.com or @amalitechtraining.org email

### 3. Test Admin Flow
1. Login as admin
2. Go to `/tasks/rest`
3. Create a task (if needed via API)
4. Assign task to member user
5. Update task status
6. Close task

### 4. Test Member Flow
1. Login as member
2. Go to `/tasks/rest`
3. View assigned tasks only
4. Update task status
5. Verify cannot assign or close tasks

### 5. Test Notifications
- Assign a task → Member receives email
- Update status → Admin receives email
- Close task → Assigned users receive email

## Troubleshooting

### Frontend Issues
**Problem**: Tasks not loading
- Check API endpoint in `.env.local`
- Verify Cognito credentials
- Check browser console for errors

**Problem**: Authentication fails
- Verify User Pool ID and Client ID
- Check email domain is allowed
- Ensure user is in correct Cognito group

### Backend Issues
**Problem**: 401 Unauthorized
- Check JWT token is being sent
- Verify Cognito authorizer configuration
- Check user has valid session

**Problem**: 403 Forbidden
- Verify user has correct role (Admin/Member)
- Check RBAC logic in Lambda
- Ensure user is in Cognito group

**Problem**: Email notifications not sent
- Verify SES email is verified
- Check EventBridge rules are active
- Review Lambda logs for errors

## Architecture Decisions

### Why REST API?
- Simple integration with existing Lambda functions
- Direct mapping to CRUD operations
- Easy to test and debug
- No GraphQL schema complexity

### Why React Query?
- Automatic caching and refetching
- Optimistic updates
- Error handling
- Loading states

### Why Single-Table DynamoDB?
- Cost-effective
- Fast queries with GSI
- Scalable design
- Supports complex access patterns

## Next Steps

1. **Add Create Task UI** - Form to create tasks from frontend
2. **Add Task Details Page** - View full task information
3. **Add Comments** - Task discussion feature
4. **Add File Attachments** - S3 integration
5. **Add Real-time Updates** - WebSocket subscriptions
6. **Add Search** - OpenSearch integration
7. **Add Analytics** - Task metrics and reports

## Support

- Check logs: `aws logs tail /aws/lambda/task-manager-sandbox-task-api --follow`
- Test API: `curl -H "Authorization: Bearer $TOKEN" $API_URL/tasks`
- Verify SES: `aws ses get-identity-verification-attributes --identities your@email.com`
