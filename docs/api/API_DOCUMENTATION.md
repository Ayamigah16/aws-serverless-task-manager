# API Documentation

## Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}/tasks
```

Get your API URL:
```bash
cd terraform
terraform output api_gateway_url
```

---

## Authentication

All endpoints require JWT token from Cognito:

```http
Authorization: Bearer {jwt-token}
```

Get JWT token by signing in through Cognito Hosted UI or using AWS Amplify SDK.

---

## Admin Endpoints

### 1. Create Task

**Endpoint:** `POST /tasks`  
**Authorization:** Admin only  
**Description:** Create a new task

**Request:**
```json
{
  "title": "Setup AWS Infrastructure",
  "description": "Configure VPC, subnets, and security groups",
  "priority": "HIGH"
}
```

**Response:** `201 Created`
```json
{
  "taskId": "123e4567-e89b-12d3-a456-426614174000",
  "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
  "SK": "METADATA",
  "Title": "Setup AWS Infrastructure",
  "Description": "Configure VPC, subnets, and security groups",
  "Priority": "HIGH",
  "Status": "OPEN",
  "CreatedBy": "user-id",
  "CreatedAt": 1707000000000,
  "UpdatedAt": 1707000000000
}
```

**Errors:**
- `400` - Title is required
- `403` - Only admins can create tasks

---

### 2. Update Task

**Endpoint:** `PUT /tasks/{taskId}`  
**Authorization:** Admin only  
**Description:** Update task details

**Request:**
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "priority": "MEDIUM"
}
```

**Response:** `200 OK`
```json
{
  "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
  "SK": "METADATA",
  "Title": "Updated Title",
  "Description": "Updated description",
  "Priority": "MEDIUM",
  "UpdatedAt": 1707000100000
}
```

**Errors:**
- `403` - Only admins can update tasks
- `404` - Task not found

---

### 3. Assign Task

**Endpoint:** `POST /tasks/{taskId}/assign`  
**Authorization:** Admin only  
**Description:** Assign task to a user

**Request:**
```json
{
  "assignedTo": "user-123"
}
```

**Response:** `200 OK`
```json
{
  "message": "Task assigned successfully",
  "assignment": {
    "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
    "SK": "ASSIGNMENT#user-123",
    "TaskId": "123e4567-e89b-12d3-a456-426614174000",
    "UserId": "user-123",
    "AssignedBy": "admin-user-id",
    "AssignedAt": 1707000200000
  }
}
```

**Errors:**
- `400` - assignedTo is required / User not found or deactivated
- `403` - Only admins can assign tasks
- `404` - Task not found
- `409` - Task already assigned to this user

---

### 4. Close Task

**Endpoint:** `POST /tasks/{taskId}/close`  
**Authorization:** Admin only  
**Description:** Close a task

**Response:** `200 OK`
```json
{
  "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
  "SK": "METADATA",
  "Status": "CLOSED",
  "ClosedBy": "admin-user-id",
  "ClosedAt": 1707000300000,
  "UpdatedAt": 1707000300000
}
```

**Errors:**
- `403` - Only admins can close tasks
- `404` - Task not found

---

### 5. Delete Task

**Endpoint:** `DELETE /tasks/{taskId}`  
**Authorization:** Admin only  
**Description:** Delete a task

**Response:** `200 OK`
```json
{
  "message": "Task deleted successfully"
}
```

**Errors:**
- `403` - Only admins can delete tasks
- `404` - Task not found

---

## Member Endpoints

### 6. List Tasks

**Endpoint:** `GET /tasks`  
**Authorization:** Required  
**Description:** List tasks (all for admin, assigned only for members)

**Response:** `200 OK`
```json
{
  "tasks": [
    {
      "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
      "SK": "METADATA",
      "TaskId": "123e4567-e89b-12d3-a456-426614174000",
      "Title": "Setup AWS Infrastructure",
      "Description": "Configure VPC, subnets, and security groups",
      "Priority": "HIGH",
      "Status": "OPEN",
      "CreatedBy": "admin-id",
      "CreatedAt": 1707000000000
    }
  ],
  "count": 1
}
```

---

### 7. Get Task

**Endpoint:** `GET /tasks/{taskId}`  
**Authorization:** Required  
**Description:** Get task details (members can only view assigned tasks)

**Response:** `200 OK`
```json
{
  "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
  "SK": "METADATA",
  "TaskId": "123e4567-e89b-12d3-a456-426614174000",
  "Title": "Setup AWS Infrastructure",
  "Description": "Configure VPC, subnets, and security groups",
  "Priority": "HIGH",
  "Status": "OPEN",
  "CreatedBy": "admin-id",
  "CreatedAt": 1707000000000,
  "UpdatedAt": 1707000000000
}
```

**Errors:**
- `403` - You are not assigned to this task (for members)
- `404` - Task not found

---

### 8. Update Task Status

**Endpoint:** `PUT /tasks/{taskId}/status`  
**Authorization:** Required (must be assigned to task)  
**Description:** Update task status

**Request:**
```json
{
  "status": "IN_PROGRESS"
}
```

**Valid statuses:** `OPEN`, `IN_PROGRESS`, `COMPLETED`

**Response:** `200 OK`
```json
{
  "PK": "TASK#123e4567-e89b-12d3-a456-426614174000",
  "SK": "METADATA",
  "Status": "IN_PROGRESS",
  "UpdatedBy": "user-id",
  "UpdatedAt": 1707000400000
}
```

**Errors:**
- `400` - Valid status is required
- `403` - You are not assigned to this task
- `404` - Task not found

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message"
}
```

### HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

---

## CORS Headers

All responses include CORS headers:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token
Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS
```

---

## Rate Limiting

- Rate limit: 1000 requests/second
- Burst limit: 2000 requests

Exceeding limits returns `429 Too Many Requests`.

---

## Testing with curl

### Get JWT Token
Sign in through Cognito Hosted UI or use AWS Amplify SDK to get JWT token.

### Set Variables
```bash
API_URL="https://your-api-id.execute-api.region.amazonaws.com/sandbox/tasks"
JWT_TOKEN="your-jwt-token-here"
```

### Create Task (Admin)
```bash
curl -X POST "${API_URL}" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Task",
    "description": "Test Description",
    "priority": "HIGH"
  }'
```

### List Tasks
```bash
curl -X GET "${API_URL}" \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

### Get Task
```bash
TASK_ID="your-task-id"
curl -X GET "${API_URL}/${TASK_ID}" \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

### Update Task Status
```bash
curl -X PUT "${API_URL}/${TASK_ID}/status" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"status": "IN_PROGRESS"}'
```

### Assign Task (Admin)
```bash
curl -X POST "${API_URL}/${TASK_ID}/assign" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"assignedTo": "user-id"}'
```

### Close Task (Admin)
```bash
curl -X POST "${API_URL}/${TASK_ID}/close" \
  -H "Authorization: Bearer ${JWT_TOKEN}"
```

---

## Testing with Postman

1. Import collection from `docs/api/postman-collection.json`
2. Set environment variables:
   - `api_url`: Your API Gateway URL
   - `jwt_token`: Your Cognito JWT token
3. Run requests

---

## Events Published

The API publishes events to EventBridge:

- `TaskCreated` - When task is created
- `TaskAssigned` - When task is assigned
- `TaskStatusUpdated` - When status changes
- `TaskClosed` - When task is closed

These events trigger email notifications (Phase 6).

---

**API Version:** 1.0  
**Last Updated:** Phase 5 Complete  
**Status:** Production Ready
