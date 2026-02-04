# Data Flow & Database Design

## DynamoDB Single-Table Design

```mermaid
erDiagram
    TASK_TABLE {
        string PK "Partition Key"
        string SK "Sort Key"
        string EntityType "TASK | USER | ASSIGNMENT"
        string TaskId "UUID"
        string UserId "Cognito Sub"
        string Title "Task title"
        string Description "Task description"
        string Status "OPEN | IN_PROGRESS | COMPLETED | CLOSED"
        string Priority "LOW | MEDIUM | HIGH"
        string CreatedBy "Admin user ID"
        string AssignedTo "Member user ID"
        number CreatedAt "Timestamp"
        number UpdatedAt "Timestamp"
        string Email "User email"
        string UserStatus "ACTIVE | DEACTIVATED"
        string[] Groups "Cognito groups"
    }
```

## Access Patterns & Key Design

### Pattern 1: Get Task by ID
```
PK: TASK#<taskId>
SK: METADATA
```

### Pattern 2: Get User Profile
```
PK: USER#<userId>
SK: PROFILE
```

### Pattern 3: Get Task Assignments
```
PK: TASK#<taskId>
SK: ASSIGNMENT#<userId>
```

### Pattern 4: Get User's Assigned Tasks
```
GSI1-PK: USER#<userId>
GSI1-SK: TASK#<taskId>
```

### Pattern 5: Query Tasks by Status
```
GSI2-PK: STATUS#<status>
GSI2-SK: CREATED_AT#<timestamp>
```

## Table Structure Example

```mermaid
graph TB
    subgraph "Main Table: TaskManagement"
        subgraph "Task Records"
            T1["PK: TASK#123<br/>SK: METADATA<br/>Title: Fix bug<br/>Status: OPEN<br/>CreatedBy: USER#456"]
            T2["PK: TASK#124<br/>SK: METADATA<br/>Title: Deploy app<br/>Status: IN_PROGRESS"]
        end
        
        subgraph "User Records"
            U1["PK: USER#456<br/>SK: PROFILE<br/>Email: admin@amalitech.com<br/>Groups: [Admins]<br/>Status: ACTIVE"]
            U2["PK: USER#789<br/>SK: PROFILE<br/>Email: member@amalitech.com<br/>Groups: [Members]<br/>Status: ACTIVE"]
        end
        
        subgraph "Assignment Records"
            A1["PK: TASK#123<br/>SK: ASSIGNMENT#789<br/>AssignedBy: USER#456<br/>AssignedAt: 1704067200"]
            A2["PK: TASK#124<br/>SK: ASSIGNMENT#789<br/>AssignedBy: USER#456<br/>AssignedAt: 1704067300"]
        end
    end
    
    subgraph "GSI1: UserTasksIndex"
        G1["GSI1-PK: USER#789<br/>GSI1-SK: TASK#123"]
        G2["GSI1-PK: USER#789<br/>GSI1-SK: TASK#124"]
    end
    
    subgraph "GSI2: TaskStatusIndex"
        G3["GSI2-PK: STATUS#OPEN<br/>GSI2-SK: 1704067200"]
        G4["GSI2-PK: STATUS#IN_PROGRESS<br/>GSI2-SK: 1704067300"]
    end
```

## Task Creation Flow

```mermaid
sequenceDiagram
    actor Admin
    participant API as Task API Lambda
    participant DDB as DynamoDB
    participant EB as EventBridge

    Admin->>API: POST /tasks<br/>{title, description, priority}
    
    API->>API: Validate admin role
    API->>API: Generate task ID
    API->>API: Validate input
    
    API->>DDB: PutItem (Task Metadata)
    Note over DDB: PK: TASK#123<br/>SK: METADATA<br/>Status: OPEN
    
    DDB->>API: Success
    
    API->>EB: Publish TaskCreated event
    Note over EB: Event: TaskCreated<br/>TaskId: 123<br/>CreatedBy: USER#456
    
    API->>Admin: 201 Created<br/>{taskId: 123}
```

## Task Assignment Flow

```mermaid
sequenceDiagram
    actor Admin
    participant API as Task API Lambda
    participant DDB as DynamoDB
    participant EB as EventBridge
    participant NH as Notification Handler
    participant SES as Amazon SES
    actor Member

    Admin->>API: POST /tasks/123/assign<br/>{userId: 789}
    
    API->>API: Validate admin role
    
    API->>DDB: Query: Check task exists
    DDB->>API: Task found
    
    API->>DDB: Query: Check user exists & active
    DDB->>API: User active
    
    API->>DDB: Query: Check duplicate assignment
    DDB->>API: No duplicate
    
    API->>DDB: PutItem (Assignment)<br/>Condition: Not exists
    Note over DDB: PK: TASK#123<br/>SK: ASSIGNMENT#789<br/>AssignedBy: USER#456
    
    DDB->>API: Success
    
    API->>EB: Publish TaskAssigned event
    Note over EB: Event: TaskAssigned<br/>TaskId: 123<br/>UserId: 789
    
    EB->>NH: Trigger notification
    
    NH->>DDB: Get user email
    DDB->>NH: member@amalitech.com
    
    NH->>DDB: Check user status
    DDB->>NH: ACTIVE
    
    NH->>SES: Send email
    SES->>Member: 📧 Task assigned notification
    
    API->>Admin: 200 OK
```

## Task Status Update Flow

```mermaid
sequenceDiagram
    actor Member
    participant API as Task API Lambda
    participant DDB as DynamoDB
    participant EB as EventBridge
    participant NH as Notification Handler
    participant SES as Amazon SES
    actor Admin

    Member->>API: PUT /tasks/123/status<br/>{status: IN_PROGRESS}
    
    API->>API: Extract user ID from JWT
    
    API->>DDB: Query: Check assignment
    Note over DDB: PK: TASK#123<br/>SK: ASSIGNMENT#789
    
    alt User is assigned
        DDB->>API: Assignment found
        
        API->>DDB: UpdateItem (Task status)
        Note over DDB: Update Status<br/>Add UpdatedBy<br/>Update UpdatedAt
        
        DDB->>API: Success
        
        API->>EB: Publish TaskStatusUpdated event
        Note over EB: Event: TaskStatusUpdated<br/>TaskId: 123<br/>NewStatus: IN_PROGRESS<br/>UpdatedBy: USER#789
        
        EB->>NH: Trigger notification
        
        NH->>DDB: Get all assigned users + admin
        DDB->>NH: [USER#456, USER#789]
        
        NH->>DDB: Filter active users
        DDB->>NH: All active
        
        NH->>SES: Send emails to all
        SES->>Admin: 📧 Status update notification
        SES->>Member: 📧 Status update notification
        
        API->>Member: 200 OK
    else User not assigned
        DDB->>API: No assignment
        API->>Member: 403 Forbidden
    end
```

## Duplicate Assignment Prevention

```mermaid
flowchart TD
    Start([Assign Task Request]) --> Extract[Extract Task ID & User ID]
    Extract --> CheckTask{Task Exists?}
    
    CheckTask -->|No| NotFound[Return 404 Not Found]
    CheckTask -->|Yes| CheckUser{User Exists<br/>& Active?}
    
    CheckUser -->|No| Invalid[Return 400 Bad Request]
    CheckUser -->|Yes| CheckDuplicate{Assignment<br/>Exists?}
    
    CheckDuplicate -->|Yes| Duplicate[Return 409 Conflict<br/>Already Assigned]
    CheckDuplicate -->|No| ConditionalWrite[DynamoDB PutItem<br/>with Condition Expression]
    
    ConditionalWrite --> WriteSuccess{Write<br/>Successful?}
    
    WriteSuccess -->|Yes| EmitEvent[Emit TaskAssigned Event]
    WriteSuccess -->|No| RaceCondition[Return 409 Conflict<br/>Race Condition]
    
    EmitEvent --> Success[Return 200 OK]
    
    NotFound --> End([End])
    Invalid --> End
    Duplicate --> End
    RaceCondition --> End
    Success --> End

    style Start fill:#4ECDC4
    style Success fill:#51CF66
    style NotFound fill:#FF6B6B
    style Invalid fill:#FF6B6B
    style Duplicate fill:#FF6B6B
    style RaceCondition fill:#FF6B6B
    style End fill:#868E96
```

## DynamoDB Conditional Write Expression

```javascript
// Prevent duplicate assignments
const params = {
  TableName: 'TaskManagement',
  Item: {
    PK: `TASK#${taskId}`,
    SK: `ASSIGNMENT#${userId}`,
    AssignedBy: adminUserId,
    AssignedAt: Date.now(),
    EntityType: 'ASSIGNMENT'
  },
  ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
};

// This will fail if assignment already exists
await dynamodb.put(params).promise();
```

## Query Examples

### 1. Get All Tasks for a User
```javascript
const params = {
  TableName: 'TaskManagement',
  IndexName: 'GSI1-UserTasksIndex',
  KeyConditionExpression: 'GSI1PK = :userId',
  ExpressionAttributeValues: {
    ':userId': `USER#${userId}`
  }
};
```

### 2. Get Tasks by Status
```javascript
const params = {
  TableName: 'TaskManagement',
  IndexName: 'GSI2-TaskStatusIndex',
  KeyConditionExpression: 'GSI2PK = :status',
  ExpressionAttributeValues: {
    ':status': `STATUS#OPEN`
  }
};
```

### 3. Get Task with All Assignments
```javascript
const params = {
  TableName: 'TaskManagement',
  KeyConditionExpression: 'PK = :taskId',
  ExpressionAttributeValues: {
    ':taskId': `TASK#${taskId}`
  }
};
// Returns: METADATA + all ASSIGNMENT# records
```

## Data Consistency

### Strong Consistency
- Used for: Assignment checks, duplicate prevention
- Cost: 2x read capacity units
- Benefit: Guaranteed latest data

### Eventually Consistent
- Used for: Task listings, user profiles
- Cost: 1x read capacity units
- Benefit: Lower cost, acceptable for most reads

## Capacity Planning

### On-Demand Mode (Recommended for Sandbox)
- No capacity planning required
- Pay per request
- Auto-scales instantly
- Cost: $1.25 per million writes, $0.25 per million reads

### Provisioned Mode (Production)
- Predictable costs
- Reserved capacity
- Auto-scaling available
- Cost: Lower for consistent workloads

---

**Diagram Version**: 1.0  
**Last Updated**: Phase 1 Completion
