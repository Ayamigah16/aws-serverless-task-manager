# Security Architecture

## Defense in Depth - Security Layers

```mermaid
graph TB
    subgraph "Layer 1: Network Security"
        HTTPS[HTTPS/TLS 1.2+<br/>Encryption in Transit]
        WAF[AWS WAF<br/>SQL Injection, XSS Protection]
        CloudFront[CloudFront<br/>DDoS Protection]
    end

    subgraph "Layer 2: Authentication"
        Cognito[Amazon Cognito<br/>JWT Tokens]
        PreSignup[Pre Sign-Up Trigger<br/>Domain Validation]
        EmailVerify[Email Verification<br/>Required]
    end

    subgraph "Layer 3: Authorization"
        APIAuth[API Gateway<br/>Cognito Authorizer]
        RBAC[Lambda RBAC<br/>Group-Based Access]
    end

    subgraph "Layer 4: Application Security"
        InputVal[Input Validation<br/>Schema Validation]
        OutputEnc[Output Encoding<br/>XSS Prevention]
        RateLimit[Rate Limiting<br/>Throttling]
    end

    subgraph "Layer 5: Data Security"
        DDBEnc[DynamoDB Encryption<br/>at Rest]
        CondWrite[Conditional Writes<br/>Race Condition Prevention]
        SSM[SSM Parameter Store<br/>Secrets Management]
    end

    subgraph "Layer 6: Monitoring & Audit"
        CloudWatch[CloudWatch Logs<br/>All Actions Logged]
        CloudTrail[CloudTrail<br/>API Audit Trail]
        XRay[X-Ray Tracing<br/>Request Tracking]
    end

    User[👤 User] --> HTTPS
    HTTPS --> WAF
    WAF --> CloudFront
    CloudFront --> Cognito
    Cognito --> PreSignup
    Cognito --> EmailVerify
    EmailVerify --> APIAuth
    APIAuth --> RBAC
    RBAC --> InputVal
    InputVal --> OutputEnc
    OutputEnc --> RateLimit
    RateLimit --> DDBEnc
    DDBEnc --> CondWrite
    CondWrite --> SSM
    SSM --> CloudWatch
    CloudWatch --> CloudTrail
    CloudTrail --> XRay

    style HTTPS fill:#4ECDC4
    style Cognito fill:#4ECDC4
    style APIAuth fill:#4ECDC4
    style DDBEnc fill:#4ECDC4
    style CloudWatch fill:#B197FC
```

## Threat Model & Mitigations

```mermaid
graph LR
    subgraph "Threats"
        T1[Unauthorized Access]
        T2[Data Breach]
        T3[Injection Attacks]
        T4[DDoS]
        T5[Privilege Escalation]
        T6[Data Tampering]
    end

    subgraph "Mitigations"
        M1[Cognito + JWT]
        M2[Encryption + IAM]
        M3[Input Validation + WAF]
        M4[WAF + Throttling]
        M5[RBAC in Lambda]
        M6[Conditional Writes]
    end

    T1 --> M1
    T2 --> M2
    T3 --> M3
    T4 --> M4
    T5 --> M5
    T6 --> M6

    style T1 fill:#FF6B6B
    style T2 fill:#FF6B6B
    style T3 fill:#FF6B6B
    style T4 fill:#FF6B6B
    style T5 fill:#FF6B6B
    style T6 fill:#FF6B6B
    style M1 fill:#51CF66
    style M2 fill:#51CF66
    style M3 fill:#51CF66
    style M4 fill:#51CF66
    style M5 fill:#51CF66
    style M6 fill:#51CF66
```

## IAM Least Privilege Model

```mermaid
graph TB
    subgraph "Lambda Execution Roles"
        subgraph "Pre Sign-Up Lambda"
            PSRole[IAM Role: PreSignupLambdaRole]
            PSPol1[CloudWatch Logs: Write]
        end

        subgraph "Task API Lambda"
            TARole[IAM Role: TaskApiLambdaRole]
            TAPol1[DynamoDB: GetItem, PutItem, UpdateItem, Query]
            TAPol2[EventBridge: PutEvents]
            TAPol3[CloudWatch Logs: Write]
            TAPol4[X-Ray: PutTraceSegments]
            TAPol5[SSM: GetParameter]
        end

        subgraph "Notification Handler Lambda"
            NHRole[IAM Role: NotificationHandlerRole]
            NHPol1[DynamoDB: Query, GetItem]
            NHPol2[SES: SendEmail]
            NHPol3[CloudWatch Logs: Write]
            NHPol4[X-Ray: PutTraceSegments]
        end
    end

    PSRole --> PSPol1
    TARole --> TAPol1
    TARole --> TAPol2
    TARole --> TAPol3
    TARole --> TAPol4
    TARole --> TAPol5
    NHRole --> NHPol1
    NHRole --> NHPol2
    NHRole --> NHPol3
    NHRole --> NHPol4

    style PSRole fill:#FFA07A
    style TARole fill:#FFA07A
    style NHRole fill:#FFA07A
```

## IAM Policy Example (Task API Lambda)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:123456789012:table/TaskManagement",
        "arn:aws:dynamodb:us-east-1:123456789012:table/TaskManagement/index/*"
      ]
    },
    {
      "Sid": "EventBridgeAccess",
      "Effect": "Allow",
      "Action": "events:PutEvents",
      "Resource": "arn:aws:events:us-east-1:123456789012:event-bus/default"
    },
    {
      "Sid": "CloudWatchLogsAccess",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/lambda/task-api:*"
    },
    {
      "Sid": "XRayAccess",
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMParameterAccess",
      "Effect": "Allow",
      "Action": "ssm:GetParameter",
      "Resource": "arn:aws:ssm:us-east-1:123456789012:parameter/task-manager/*"
    }
  ]
}
```

## Secrets Management Flow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Terraform as Terraform
    participant SSM as SSM Parameter Store
    participant Lambda as Lambda Function
    participant App as Application Code

    Dev->>Terraform: Define secrets (not values)
    Terraform->>SSM: Create parameter placeholders
    
    Note over Dev,SSM: Manual step (one-time)
    Dev->>SSM: Store secret values via AWS CLI
    
    Note over Lambda,App: Runtime
    Lambda->>Lambda: Cold start
    Lambda->>SSM: GetParameter (SecureString)
    SSM->>Lambda: Encrypted secret
    Lambda->>Lambda: Decrypt (KMS)
    Lambda->>App: Provide secret as env var
    
    Note over Lambda: Warm invocations use cached value
```

## Encryption Architecture

```mermaid
graph TB
    subgraph "Data at Rest"
        DDB[DynamoDB<br/>AWS Managed KMS]
        S3[S3 Buckets<br/>AES-256]
        SSM[SSM Parameters<br/>KMS Encrypted]
    end

    subgraph "Data in Transit"
        TLS[TLS 1.2+<br/>All Connections]
        HTTPS[HTTPS Only<br/>No HTTP]
    end

    subgraph "Key Management"
        KMS[AWS KMS<br/>Customer Managed Keys]
        Rotation[Automatic Key Rotation<br/>Enabled]
    end

    DDB --> KMS
    SSM --> KMS
    KMS --> Rotation
    
    User[User] -->|HTTPS| Frontend[Frontend]
    Frontend -->|HTTPS| API[API Gateway]
    API -->|TLS| Lambda[Lambda]
    Lambda -->|TLS| DDB

    style DDB fill:#98D8C8
    style KMS fill:#4ECDC4
    style TLS fill:#4ECDC4
```

## API Security Controls

```mermaid
flowchart TD
    Request[API Request] --> WAF{AWS WAF<br/>Rules}
    
    WAF -->|Block| Block1[403 Forbidden<br/>SQL Injection Detected]
    WAF -->|Block| Block2[403 Forbidden<br/>XSS Detected]
    WAF -->|Block| Block3[429 Too Many Requests<br/>Rate Limit Exceeded]
    
    WAF -->|Pass| Auth{Cognito<br/>Authorizer}
    
    Auth -->|Invalid| Unauth[401 Unauthorized<br/>Invalid Token]
    Auth -->|Valid| Throttle{API Gateway<br/>Throttling}
    
    Throttle -->|Exceeded| Throttled[429 Too Many Requests<br/>Throttle Limit]
    Throttle -->|OK| Validate{Input<br/>Validation}
    
    Validate -->|Invalid| BadRequest[400 Bad Request<br/>Invalid Input]
    Validate -->|Valid| RBAC{RBAC<br/>Check}
    
    RBAC -->|Denied| Forbidden[403 Forbidden<br/>Insufficient Permissions]
    RBAC -->|Allowed| Process[Process Request]
    
    Process --> Success[200 OK]
    
    Block1 --> End([End])
    Block2 --> End
    Block3 --> End
    Unauth --> End
    Throttled --> End
    BadRequest --> End
    Forbidden --> End
    Success --> End

    style Request fill:#4ECDC4
    style Success fill:#51CF66
    style Block1 fill:#FF6B6B
    style Block2 fill:#FF6B6B
    style Block3 fill:#FF6B6B
    style Unauth fill:#FF6B6B
    style Throttled fill:#FF6B6B
    style BadRequest fill:#FF6B6B
    style Forbidden fill:#FF6B6B
```

## Security Monitoring & Alerting

```mermaid
graph TB
    subgraph "Security Events"
        E1[Failed Login Attempts]
        E2[Unauthorized API Calls]
        E3[IAM Policy Changes]
        E4[Unusual Data Access]
        E5[High Error Rates]
    end

    subgraph "Detection"
        CloudWatch[CloudWatch Logs<br/>Metric Filters]
        CloudTrail[CloudTrail<br/>API Monitoring]
        GuardDuty[GuardDuty<br/>Threat Detection]
    end

    subgraph "Alerting"
        Alarms[CloudWatch Alarms]
        SNS[SNS Topics]
        Email[Email Notifications]
        Slack[Slack Integration]
    end

    subgraph "Response"
        Runbook[Security Runbook]
        Team[Security Team]
        Remediation[Automated Remediation]
    end

    E1 --> CloudWatch
    E2 --> CloudWatch
    E3 --> CloudTrail
    E4 --> CloudTrail
    E5 --> CloudWatch
    
    CloudWatch --> Alarms
    CloudTrail --> Alarms
    GuardDuty --> Alarms
    
    Alarms --> SNS
    SNS --> Email
    SNS --> Slack
    
    Email --> Team
    Slack --> Team
    Team --> Runbook
    Runbook --> Remediation

    style E1 fill:#FF6B6B
    style E2 fill:#FF6B6B
    style E3 fill:#FF6B6B
    style E4 fill:#FF6B6B
    style E5 fill:#FF6B6B
    style Alarms fill:#FFD93D
    style Team fill:#51CF66
```

## Security Checklist

### Authentication ✅
- [x] Email verification required
- [x] Domain restrictions enforced
- [x] JWT token validation
- [x] Token expiration (1 hour)
- [x] Secure token storage

### Authorization ✅
- [x] Cognito Authorizer on API Gateway
- [x] RBAC enforcement in Lambda
- [x] Group-based permissions
- [x] Least privilege IAM policies

### Data Protection ✅
- [x] Encryption at rest (DynamoDB)
- [x] Encryption in transit (TLS 1.2+)
- [x] Secrets in SSM Parameter Store
- [x] No hardcoded credentials
- [x] Conditional writes (race conditions)

### Network Security ✅
- [x] HTTPS only
- [x] WAF protection
- [x] API throttling
- [x] CORS restrictions
- [x] DDoS protection (CloudFront)

### Monitoring & Audit ✅
- [x] CloudWatch logging
- [x] CloudTrail audit trail
- [x] X-Ray tracing
- [x] Security alarms
- [x] Failed login tracking

### Compliance ✅
- [x] OWASP Top 10 addressed
- [x] AWS Well-Architected
- [x] Data retention policies
- [x] Incident response plan
- [x] Regular security reviews

## Security Testing Strategy

### 1. SAST (Static Application Security Testing)
- ESLint security plugins
- Bandit (Python)
- tfsec (Terraform)
- Checkov (IaC)

### 2. DAST (Dynamic Application Security Testing)
- OWASP ZAP
- API security testing
- Penetration testing

### 3. Dependency Scanning
- Snyk
- npm audit
- Dependabot

### 4. Secret Scanning
- git-secrets
- TruffleHog
- Pre-commit hooks

### 5. Manual Testing
- Authentication bypass attempts
- RBAC validation
- JWT tampering
- SQL injection (N/A for DynamoDB)
- XSS attempts

---

**Diagram Version**: 1.0  
**Last Updated**: Phase 1 Completion
