# Authentication & Authorization Flow

## User Sign-Up Flow

```mermaid
sequenceDiagram
    actor User
    participant Amplify as AWS Amplify
    participant Cognito as Cognito User Pool
    participant PreSignup as Pre Sign-Up Lambda
    participant CloudWatch as CloudWatch Logs

    User->>Amplify: Enter email & password
    Amplify->>Cognito: Sign up request
    Cognito->>PreSignup: Trigger Pre Sign-Up
    
    alt Valid Domain (@amalitech.com or @amalitechtraining.org)
        PreSignup->>CloudWatch: Log: Valid domain
        PreSignup->>Cognito: Auto-confirm user
        Cognito->>User: Send verification email
        User->>Cognito: Click verification link
        Cognito->>User: Email verified ✅
    else Invalid Domain
        PreSignup->>CloudWatch: Log: Blocked domain
        PreSignup->>Cognito: Reject sign-up
        Cognito->>User: Error: Invalid email domain ❌
    end
```

## User Login Flow

```mermaid
sequenceDiagram
    actor User
    participant Amplify as React App
    participant Hosted as Cognito Hosted UI
    participant Cognito as Cognito User Pool
    participant Groups as Cognito Groups

    User->>Amplify: Click "Login"
    Amplify->>Hosted: Redirect to Hosted UI
    User->>Hosted: Enter credentials
    
    alt Email Verified
        Hosted->>Cognito: Authenticate
        Cognito->>Groups: Get user groups
        Groups->>Cognito: Return groups (Admin/Member)
        Cognito->>Hosted: Generate JWT tokens
        Note over Cognito: JWT includes:<br/>- User ID<br/>- Email<br/>- Groups<br/>- Expiration
        Hosted->>Amplify: Redirect with tokens
        Amplify->>Amplify: Store tokens securely
        Amplify->>User: Show dashboard ✅
    else Email Not Verified
        Hosted->>User: Error: Verify email first ❌
    end
```

## API Request Authorization Flow

```mermaid
sequenceDiagram
    actor User
    participant Amplify as React App
    participant APIGW as API Gateway
    participant Authorizer as Cognito Authorizer
    participant Cognito as Cognito User Pool
    participant Lambda as Task API Lambda
    participant DDB as DynamoDB

    User->>Amplify: Perform action (e.g., create task)
    Amplify->>APIGW: API Request + JWT Token
    
    APIGW->>Authorizer: Validate token
    Authorizer->>Cognito: Verify signature & expiration
    
    alt Valid Token
        Cognito->>Authorizer: Token valid ✅
        Authorizer->>APIGW: Allow request + user context
        APIGW->>Lambda: Invoke with user context
        
        Lambda->>Lambda: Extract user groups from JWT
        
        alt Admin Action (e.g., create task)
            alt User is Admin
                Lambda->>DDB: Execute operation
                DDB->>Lambda: Success
                Lambda->>APIGW: 200 OK
                APIGW->>Amplify: Success response
                Amplify->>User: Show success ✅
            else User is Member
                Lambda->>APIGW: 403 Forbidden
                APIGW->>Amplify: Error response
                Amplify->>User: Access denied ❌
            end
        else Member Action (e.g., view tasks)
            Lambda->>DDB: Query user's tasks
            DDB->>Lambda: Return tasks
            Lambda->>APIGW: 200 OK + tasks
            APIGW->>Amplify: Success response
            Amplify->>User: Show tasks ✅
        end
        
    else Invalid Token
        Cognito->>Authorizer: Token invalid ❌
        Authorizer->>APIGW: Deny request
        APIGW->>Amplify: 401 Unauthorized
        Amplify->>Amplify: Clear tokens
        Amplify->>User: Redirect to login
    end
```

## RBAC Enforcement

```mermaid
flowchart TD
    Start([API Request Received]) --> ExtractJWT[Extract JWT Token]
    ExtractJWT --> ValidateToken{Token Valid?}
    
    ValidateToken -->|No| Unauthorized[Return 401 Unauthorized]
    ValidateToken -->|Yes| ExtractGroups[Extract User Groups from JWT]
    
    ExtractGroups --> CheckAction{What Action?}
    
    CheckAction -->|Create Task| CheckAdmin1{Is Admin?}
    CheckAction -->|Update Task| CheckAdmin2{Is Admin?}
    CheckAction -->|Assign Task| CheckAdmin3{Is Admin?}
    CheckAction -->|Close Task| CheckAdmin4{Is Admin?}
    CheckAction -->|View Tasks| AllowView[Allow - Both Roles]
    CheckAction -->|Update Status| AllowStatus[Allow - Both Roles]
    
    CheckAdmin1 -->|Yes| AllowCreate[Execute Create Task]
    CheckAdmin1 -->|No| Forbidden1[Return 403 Forbidden]
    
    CheckAdmin2 -->|Yes| AllowUpdate[Execute Update Task]
    CheckAdmin2 -->|No| Forbidden2[Return 403 Forbidden]
    
    CheckAdmin3 -->|Yes| AllowAssign[Execute Assign Task]
    CheckAdmin3 -->|No| Forbidden3[Return 403 Forbidden]
    
    CheckAdmin4 -->|Yes| AllowClose[Execute Close Task]
    CheckAdmin4 -->|No| Forbidden4[Return 403 Forbidden]
    
    AllowCreate --> Success[Return 200 OK]
    AllowUpdate --> Success
    AllowAssign --> Success
    AllowClose --> Success
    AllowView --> Success
    AllowStatus --> Success
    
    Unauthorized --> End([End])
    Forbidden1 --> End
    Forbidden2 --> End
    Forbidden3 --> End
    Forbidden4 --> End
    Success --> End

    style Start fill:#4ECDC4
    style Success fill:#51CF66
    style Unauthorized fill:#FF6B6B
    style Forbidden1 fill:#FF6B6B
    style Forbidden2 fill:#FF6B6B
    style Forbidden3 fill:#FF6B6B
    style Forbidden4 fill:#FF6B6B
    style End fill:#868E96
```

## JWT Token Structure

```json
{
  "sub": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "cognito:groups": ["Admins"],
  "email_verified": true,
  "iss": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_XXXXXXXXX",
  "cognito:username": "john.doe@amalitech.com",
  "origin_jti": "12345678-1234-1234-1234-123456789012",
  "aud": "1234567890abcdefghijklmnop",
  "event_id": "12345678-1234-1234-1234-123456789012",
  "token_use": "id",
  "auth_time": 1704067200,
  "exp": 1704070800,
  "iat": 1704067200,
  "email": "john.doe@amalitech.com"
}
```

## Security Controls

### 1. Email Domain Validation
- **Where**: Pre Sign-Up Lambda Trigger
- **When**: During user registration
- **How**: Regex validation against whitelist
- **Allowed**: @amalitech.com, @amalitechtraining.org
- **Action**: Auto-reject invalid domains

### 2. Email Verification
- **Where**: Cognito User Pool
- **When**: After sign-up
- **How**: Email with verification link
- **Enforcement**: Unverified users cannot get tokens

### 3. JWT Validation
- **Where**: API Gateway Cognito Authorizer
- **When**: Every API request
- **Checks**:
  - Signature verification
  - Token expiration
  - Issuer validation
  - Audience validation

### 4. RBAC Enforcement
- **Where**: Lambda function code
- **When**: Every API operation
- **How**: Check `cognito:groups` claim
- **Enforcement**: Return 403 for unauthorized actions

### 5. Token Expiration
- **ID Token**: 1 hour
- **Access Token**: 1 hour
- **Refresh Token**: 30 days
- **Auto-refresh**: Handled by Amplify SDK

## User Groups & Permissions

| Group | Permissions |
|-------|-------------|
| **Admins** | - Create tasks<br/>- Update tasks<br/>- Assign tasks<br/>- Close tasks<br/>- View all tasks<br/>- Update task status |
| **Members** | - View assigned tasks<br/>- Update task status |

## Error Handling

| Error Code | Scenario | User Action |
|------------|----------|-------------|
| 400 | Invalid request format | Fix request data |
| 401 | Missing/invalid token | Re-authenticate |
| 403 | Insufficient permissions | Contact admin |
| 404 | Resource not found | Verify resource ID |
| 429 | Rate limit exceeded | Retry after delay |
| 500 | Server error | Contact support |

---

**Diagram Version**: 1.0  
**Last Updated**: Phase 1 Completion
