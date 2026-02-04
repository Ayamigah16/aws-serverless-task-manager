# High-Level System Architecture

## Overview
This diagram shows the complete serverless task management system architecture on AWS.

```mermaid
graph TB
    subgraph "Client Layer"
        User[👤 User Browser]
    end

    subgraph "AWS Cloud"
        subgraph "Frontend - AWS Amplify"
            Amplify[AWS Amplify<br/>React.js SPA]
        end

        subgraph "Authentication - Amazon Cognito"
            Cognito[Cognito User Pool<br/>Email Verification<br/>Domain Restrictions]
            PreSignup[Pre Sign-Up Trigger<br/>Lambda]
            Groups[Cognito Groups<br/>Admins | Members]
        end

        subgraph "API Layer - API Gateway"
            APIGW[API Gateway REST API<br/>Cognito Authorizer<br/>WAF Protection]
        end

        subgraph "Compute - AWS Lambda"
            TaskAPI[Task API Lambda<br/>CRUD Operations<br/>RBAC Enforcement]
            NotifyHandler[Notification Handler<br/>Lambda]
        end

        subgraph "Database - DynamoDB"
            DDB[(DynamoDB<br/>Single Table Design<br/>Tasks & Assignments)]
        end

        subgraph "Event Processing"
            EventBridge[Amazon EventBridge<br/>Event Bus]
        end

        subgraph "Notifications"
            SES[Amazon SES<br/>Email Service]
        end

        subgraph "Monitoring & Security"
            CloudWatch[CloudWatch<br/>Logs & Metrics]
            XRay[X-Ray<br/>Tracing]
            SSM[SSM Parameter Store<br/>Secrets]
            CloudTrail[CloudTrail<br/>Audit Logs]
        end
    end

    %% User Flow
    User -->|HTTPS| Amplify
    Amplify -->|Sign Up/Login| Cognito
    Cognito -->|Validate Email Domain| PreSignup
    Cognito -->|JWT Token| Amplify
    Amplify -->|API Requests + JWT| APIGW

    %% API Flow
    APIGW -->|Validate JWT| Cognito
    APIGW -->|Invoke| TaskAPI
    TaskAPI -->|Read/Write| DDB
    TaskAPI -->|Emit Events| EventBridge

    %% Event Flow
    EventBridge -->|Task Events| NotifyHandler
    NotifyHandler -->|Query Users| DDB
    NotifyHandler -->|Send Email| SES
    SES -->|Email| User

    %% Security & Monitoring
    TaskAPI -.->|Logs| CloudWatch
    NotifyHandler -.->|Logs| CloudWatch
    APIGW -.->|Traces| XRay
    TaskAPI -.->|Traces| XRay
    TaskAPI -.->|Get Secrets| SSM
    Cognito -.->|Audit| CloudTrail
    DDB -.->|Audit| CloudTrail

    %% Styling
    classDef frontend fill:#FF6B6B,stroke:#C92A2A,color:#fff
    classDef auth fill:#4ECDC4,stroke:#0B7285,color:#fff
    classDef api fill:#45B7D1,stroke:#1971C2,color:#fff
    classDef compute fill:#FFA07A,stroke:#D9480F,color:#fff
    classDef database fill:#98D8C8,stroke:#087F5B,color:#fff
    classDef events fill:#FFD93D,stroke:#F08C00,color:#000
    classDef monitoring fill:#B197FC,stroke:#5F3DC4,color:#fff

    class Amplify frontend
    class Cognito,PreSignup,Groups auth
    class APIGW api
    class TaskAPI,NotifyHandler compute
    class DDB database
    class EventBridge,SES events
    class CloudWatch,XRay,SSM,CloudTrail monitoring
```

## Architecture Principles

### 1. Serverless-First
- No server management required
- Auto-scaling built-in
- Pay-per-use pricing model

### 2. Event-Driven
- Loose coupling between components
- Asynchronous processing
- Scalable notification system

### 3. Security by Design
- Authentication at every layer
- Encryption at rest and in transit
- Least-privilege IAM policies
- Comprehensive audit logging

### 4. High Availability
- Multi-AZ deployment (AWS managed)
- No single point of failure
- Automatic failover

### 5. Cost-Optimized
- On-demand pricing for DynamoDB
- Lambda pay-per-invocation
- Free tier eligible services

## Key Components

| Component | Service | Purpose |
|-----------|---------|---------|
| Frontend | AWS Amplify | Host React SPA with CI/CD |
| Authentication | Amazon Cognito | User management, JWT tokens |
| API Gateway | API Gateway | REST API with authorization |
| Compute | AWS Lambda | Serverless business logic |
| Database | DynamoDB | NoSQL single-table design |
| Events | EventBridge | Event routing and processing |
| Notifications | Amazon SES | Email delivery |
| Secrets | SSM Parameter Store | Secure configuration |
| Monitoring | CloudWatch + X-Ray | Observability |
| Audit | CloudTrail | Compliance logging |

## Data Flow

### 1. User Sign-Up Flow
```
User → Amplify → Cognito → Pre Sign-Up Lambda (validate domain) → Cognito (create user)
```

### 2. Authentication Flow
```
User → Amplify → Cognito Hosted UI → JWT Token → Amplify (store token)
```

### 3. API Request Flow
```
User → Amplify → API Gateway (validate JWT) → Lambda (RBAC check) → DynamoDB
```

### 4. Notification Flow
```
Lambda → EventBridge → Notification Handler → DynamoDB (get users) → SES → Email
```

## Security Layers

1. **Network**: HTTPS only, WAF protection
2. **Authentication**: Cognito JWT validation
3. **Authorization**: RBAC in Lambda functions
4. **Data**: Encryption at rest (DynamoDB, S3)
5. **Audit**: CloudTrail logging all API calls

## Scalability

- **API Gateway**: 10,000 requests/second (default)
- **Lambda**: 1,000 concurrent executions (default)
- **DynamoDB**: Unlimited throughput (on-demand)
- **Cognito**: 120 requests/second per user pool

---

**Diagram Version**: 1.0  
**Last Updated**: Phase 1 Completion
