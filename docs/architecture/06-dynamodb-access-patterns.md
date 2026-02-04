# DynamoDB Single-Table Design - Access Patterns

## Table Structure

**Table Name**: `task-manager-sandbox-tasks`

**Primary Key**:
- Partition Key (PK): String
- Sort Key (SK): String

**Global Secondary Indexes**:
- GSI1: GSI1PK (Partition Key), GSI1SK (Sort Key)
- GSI2: GSI2PK (Partition Key), GSI2SK (Sort Key)

---

## Entity Types

### 1. Task Metadata
```
PK: TASK#<taskId>
SK: METADATA
EntityType: TASK
TaskId: <uuid>
Title: <string>
Description: <string>
Priority: OPEN | IN_PROGRESS | COMPLETED | CLOSED
Status: LOW | MEDIUM | HIGH
CreatedBy: <userId>
CreatedAt: <timestamp>
UpdatedAt: <timestamp>
GSI2PK: STATUS#<status>
GSI2SK: CREATED_AT#<timestamp>
```

### 2. User Profile
```
PK: USER#<userId>
SK: PROFILE
EntityType: USER
UserId: <uuid>
Email: <email>
UserStatus: ACTIVE | DEACTIVATED
Groups: [Admins] | [Members]
CreatedAt: <timestamp>
```

### 3. Task Assignment
```
PK: TASK#<taskId>
SK: ASSIGNMENT#<userId>
EntityType: ASSIGNMENT
TaskId: <taskId>
UserId: <userId>
AssignedBy: <adminUserId>
AssignedAt: <timestamp>
GSI1PK: USER#<userId>
GSI1SK: TASK#<taskId>
```

---

## Access Patterns

### Pattern 1: Get Task by ID
**Use Case**: View task details

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  Key: {
    PK: 'TASK#123',
    SK: 'METADATA'
  }
}
```

**Performance**: O(1) - Single item read  
**Cost**: 1 RCU (eventually consistent) or 2 RCU (strongly consistent)

---

### Pattern 2: Get User Profile
**Use Case**: Fetch user details for notifications

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  Key: {
    PK: 'USER#456',
    SK: 'PROFILE'
  }
}
```

**Performance**: O(1) - Single item read  
**Cost**: 1 RCU

---

### Pattern 3: Get All Assignments for a Task
**Use Case**: Find all users assigned to a task

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :assignment)',
  ExpressionAttributeValues: {
    ':taskId': 'TASK#123',
    ':assignment': 'ASSIGNMENT#'
  }
}
```

**Performance**: O(n) where n = number of assignments  
**Cost**: (n / 4KB) RCUs

---

### Pattern 4: Get All Tasks Assigned to a User (GSI1)
**Use Case**: Member views their assigned tasks

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  IndexName: 'GSI1',
  KeyConditionExpression: 'GSI1PK = :userId',
  ExpressionAttributeValues: {
    ':userId': 'USER#789'
  }
}
```

**Performance**: O(n) where n = number of assigned tasks  
**Cost**: (n / 4KB) RCUs  
**Note**: No table scan required

---

### Pattern 5: Get Tasks by Status (GSI2)
**Use Case**: Admin views all open tasks

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  IndexName: 'GSI2',
  KeyConditionExpression: 'GSI2PK = :status',
  ExpressionAttributeValues: {
    ':status': 'STATUS#OPEN'
  }
}
```

**Performance**: O(n) where n = number of tasks with status  
**Cost**: (n / 4KB) RCUs  
**Sorting**: By creation time (GSI2SK)

---

### Pattern 6: Check if User is Assigned to Task
**Use Case**: Validate member access before status update

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  Key: {
    PK: 'TASK#123',
    SK: 'ASSIGNMENT#789'
  }
}
```

**Performance**: O(1) - Single item read  
**Cost**: 1 RCU

---

### Pattern 7: Prevent Duplicate Assignment (Conditional Write)
**Use Case**: Ensure task not already assigned to user

**Query**:
```javascript
{
  TableName: 'TaskManagement',
  Item: {
    PK: 'TASK#123',
    SK: 'ASSIGNMENT#789',
    // ... other attributes
  },
  ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
}
```

**Performance**: O(1) - Single item write  
**Cost**: 1 WCU  
**Behavior**: Fails if assignment already exists

---

## Query Complexity Analysis

| Pattern | Type | Complexity | Scans Table? | Cost |
|---------|------|------------|--------------|------|
| Get Task | GetItem | O(1) | No | 1 RCU |
| Get User | GetItem | O(1) | No | 1 RCU |
| Task Assignments | Query | O(n) | No | n/4KB RCUs |
| User's Tasks (GSI1) | Query | O(n) | No | n/4KB RCUs |
| Tasks by Status (GSI2) | Query | O(n) | No | n/4KB RCUs |
| Check Assignment | GetItem | O(1) | No | 1 RCU |
| Prevent Duplicate | PutItem | O(1) | No | 1 WCU |

**✅ No Full Table Scans Required**

---

## Capacity Planning

### On-Demand Mode (Recommended for Sandbox)
- **Reads**: $0.25 per million requests
- **Writes**: $1.25 per million requests
- **Storage**: $0.25 per GB-month
- **Auto-scaling**: Instant
- **Best for**: Unpredictable workloads

### Provisioned Mode (Production)
- **Reads**: $0.00013 per RCU-hour
- **Writes**: $0.00065 per WCU-hour
- **Auto-scaling**: Available
- **Best for**: Predictable workloads

---

## Example Workload (100 users, 1000 tasks)

### Daily Operations
- 500 task views: 500 RCUs
- 100 task creations: 100 WCUs
- 200 task assignments: 200 WCUs
- 300 status updates: 300 WCUs
- 500 user task queries: 2500 RCUs (avg 5 tasks/user)

### Monthly Cost (On-Demand)
- Reads: (3000 * 30) / 1M * $0.25 = $0.02
- Writes: (600 * 30) / 1M * $1.25 = $0.02
- Storage: 1 GB * $0.25 = $0.25
- **Total**: ~$0.30/month

---

## Best Practices Implemented

✅ **Single-Table Design**: All entities in one table  
✅ **Composite Keys**: PK + SK for flexible queries  
✅ **GSIs for Access Patterns**: No table scans  
✅ **Conditional Writes**: Prevent race conditions  
✅ **Sparse Indexes**: Only items with GSI attributes indexed  
✅ **Timestamp Sorting**: GSI2SK for chronological order  
✅ **Efficient Queries**: O(1) or O(n) with no scans  

---

## Anti-Patterns Avoided

❌ **No Full Table Scans**: All queries use keys  
❌ **No Hot Partitions**: Well-distributed keys  
❌ **No Over-Indexing**: Only 2 GSIs needed  
❌ **No Duplicate Data**: Normalized where possible  
❌ **No Large Items**: All items < 4KB  

---

**Last Updated**: Phase 4 Implementation  
**Status**: Production-Ready Design
