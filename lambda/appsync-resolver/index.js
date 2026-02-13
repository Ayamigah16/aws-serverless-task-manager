const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');
const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client);
const eventBridge = new EventBridgeClient({});

const TABLE_NAME = process.env.TABLE_NAME;
const EVENT_BUS_NAME = process.env.EVENT_BUS_NAME;

exports.handler = async (event) => {
  console.log('AppSync Resolver Event:', JSON.stringify(event, null, 2));

  const { field, arguments: args, identity } = event;
  const userId = identity.sub;
  const isAdmin = identity.groups?.includes('Admins') || false;

  console.log('User:', userId, 'isAdmin:', isAdmin, 'groups:', identity.groups);

  try {
    switch (field) {
      case 'createTask':
        return await createTask(args.input, userId, isAdmin);
      case 'getTask':
        return await getTask(args.taskId, userId, isAdmin);
      case 'updateTask':
        return await updateTask(args.input, userId, isAdmin);
      case 'deleteTask':
        return await deleteTask(args.taskId, isAdmin);
      case 'assignTask':
        return await assignTask(args.input, userId, isAdmin);
      case 'listTasks':
        return await listTasks(args, userId, isAdmin);
      case 'listUsers':
        return await listUsers(isAdmin);
      case 'getTaskComments':
        return await getTaskComments(args.taskId);
      case 'createProject':
        return await createProject(args.input, userId, isAdmin);
      case 'createSprint':
        return await createSprint(args.input, userId, isAdmin);
      case 'addComment':
        return await addComment(args.input, userId);
      case 'getMyTasks':
        return await getMyTasks(userId, args.status);
      default:
        throw new Error(`Unknown field: ${field}`);
    }
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};

async function getTaskComments(taskId) {
  const result = await ddb.send(new QueryCommand({
    TableName: TABLE_NAME,
    KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :comment)',
    ExpressionAttributeValues: {
      ':taskId': `TASK#${taskId}`,
      ':comment': 'COMMENT#'
    }
  }));

  return result.Items || [];
}

async function listUsers(isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can list users');
  }

  const { CognitoIdentityProviderClient, ListUsersCommand, AdminListGroupsForUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
  const cognito = new CognitoIdentityProviderClient({ region: process.env.REGION });

  const listCommand = new ListUsersCommand({
    UserPoolId: process.env.USER_POOL_ID,
    Limit: 60
  });

  const response = await cognito.send(listCommand);

  const users = await Promise.all(response.Users.map(async (user) => {
    const groupsCommand = new AdminListGroupsForUserCommand({
      UserPoolId: process.env.USER_POOL_ID,
      Username: user.Username
    });

    const groupsResponse = await cognito.send(groupsCommand);
    const groups = groupsResponse.Groups.map(g => g.GroupName);

    const attributes = {};
    user.Attributes.forEach(attr => {
      attributes[attr.Name] = attr.Value;
    });

    return {
      userId: attributes.sub,
      email: attributes.email,
      groups,
      isAdmin: groups.includes('Admins'),
      enabled: user.Enabled
    };
  }));

  return users.filter(u => u.enabled);
}

async function getTask(taskId, userId, isAdmin) {
  const task = await ddb.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TASK#${taskId}`, SK: 'METADATA' }
  }));

  if (!task.Item) {
    throw new Error('Task not found');
  }

  if (!isAdmin) {
    const assignment = await ddb.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TASK#${taskId}`, SK: `ASSIGNMENT#${userId}` }
    }));
    if (!assignment.Item) {
      throw new Error('Access denied: You are not assigned to this task');
    }
  }

  // Enrich task with assignees
  return await enrichTaskWithAssignees(task.Item);
}

// Helper function to get task assignees
async function getTaskAssignees(taskId) {
  const result = await ddb.send(new QueryCommand({
    TableName: TABLE_NAME,
    KeyConditionExpression: 'PK = :pk AND begins_with(SK, :sk)',
    ExpressionAttributeValues: {
      ':pk': `TASK#${taskId}`,
      ':sk': `ASSIGNMENT#`
    }
  }));

  if (!result.Items || result.Items.length === 0) {
    return [];
  }

  // Get user details from Cognito
  const { CognitoIdentityProviderClient, AdminGetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
  const cognito = new CognitoIdentityProviderClient({ region: process.env.REGION });

  const assignees = await Promise.all(
    result.Items.map(async (assignment) => {
      try {
        const userCommand = new AdminGetUserCommand({
          UserPoolId: process.env.USER_POOL_ID,
          Username: assignment.userId
        });
        const userResponse = await cognito.send(userCommand);
        const attributes = userResponse.UserAttributes.reduce((acc, attr) => {
          acc[attr.Name] = attr.Value;
          return acc;
        }, {});

        return {
          userId: assignment.userId,
          email: attributes.email,
          name: attributes.name || attributes.email,
          enabled: userResponse.Enabled
        };
      } catch (err) {
        console.error(`Failed to get user ${assignment.userId}:`, err);
        return null;
      }
    })
  );

  return assignees.filter(a => a !== null);
}

// Enrich task with assignees array
async function enrichTaskWithAssignees(task) {
  const assignees = await getTaskAssignees(task.taskId);
  return {
    ...task,
    assignees
  };
}

async function createTask(input, userId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can create tasks');
  }

  const taskId = uuidv4();
  const timestamp = new Date().toISOString();

  const task = {
    PK: `TASK#${taskId}`,
    SK: 'METADATA',
    EntityType: 'TASK',
    taskId,
    title: input.title,
    description: input.description || '',
    priority: input.priority,
    status: 'OPEN',
    projectId: input.projectId,
    sprintId: input.sprintId,
    dueDate: input.dueDate,
    estimatedPoints: input.estimatedPoints,
    labels: input.labels || [],
    createdBy: userId,
    createdAt: timestamp,
    updatedAt: timestamp,
    GSI2PK: 'STATUS#OPEN',
    GSI2SK: `CREATED_AT#${timestamp}`,
  };

  if (input.sprintId) {
    task.GSI3PK = `SPRINT#${input.sprintId}`;
    task.GSI3SK = `TASK#${taskId}`;
  }

  if (input.projectId) {
    task.GSI4PK = `PROJECT#${input.projectId}`;
    task.GSI4SK = `CREATED_AT#${timestamp}`;
  }

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: task
  }));

  await publishEvent('TaskCreated', {
    taskId,
    title: input.title,
    priority: input.priority,
    createdBy: userId
  });

  return task;
}

async function updateTask(input, userId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can update tasks');
  }

  const { taskId, ...updates } = input;
  const timestamp = new Date().toISOString();

  const updateExpressions = [];
  const expressionAttributeNames = {};
  const expressionAttributeValues = { ':updatedAt': timestamp, ':updatedBy': userId };

  Object.entries(updates).forEach(([key, value]) => {
    if (value !== undefined) {
      const attrName = `#${key}`;
      const attrValue = `:${key}`;
      updateExpressions.push(`${attrName} = ${attrValue}`);
      expressionAttributeNames[attrName] = key;
      expressionAttributeValues[attrValue] = value;
    }
  });

  updateExpressions.push('#updatedAt = :updatedAt', '#updatedBy = :updatedBy');
  expressionAttributeNames['#updatedAt'] = 'updatedAt';
  expressionAttributeNames['#updatedBy'] = 'updatedBy';

  if (updates.status) {
    updateExpressions.push('#GSI2PK = :gsi2pk');
    expressionAttributeNames['#GSI2PK'] = 'GSI2PK';
    expressionAttributeValues[':gsi2pk'] = `STATUS#${updates.status}`;
  }

  const result = await ddb.send(new UpdateCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TASK#${taskId}`, SK: 'METADATA' },
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW'
  }));

  await publishEvent('TaskUpdated', {
    taskId,
    updates,
    updatedBy: userId
  });

  return result.Attributes;
}

async function deleteTask(taskId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can delete tasks');
  }

  await ddb.send(new DeleteCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TASK#${taskId}`, SK: 'METADATA' }
  }));

  return true;
}

async function assignTask(input, userId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can assign tasks');
  }

  const { taskId, userId: assigneeId } = input;
  const timestamp = new Date().toISOString();

  const task = await ddb.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TASK#${taskId}`, SK: 'METADATA' }
  }));

  if (!task.Item) {
    throw new Error('Task not found');
  }

  const { CognitoIdentityProviderClient, AdminGetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');
  const cognito = new CognitoIdentityProviderClient({ region: process.env.REGION });

  try {
    const userCommand = new AdminGetUserCommand({
      UserPoolId: process.env.USER_POOL_ID,
      Username: assigneeId
    });
    const userResponse = await cognito.send(userCommand);

    if (!userResponse.Enabled) {
      throw new Error('Cannot assign tasks to deactivated users');
    }
  } catch (err) {
    if (err.name === 'UserNotFoundException') {
      throw new Error('Assigned user not found');
    }
    throw err;
  }

  const assignment = {
    PK: `TASK#${taskId}`,
    SK: `ASSIGNMENT#${assigneeId}`,
    EntityType: 'ASSIGNMENT',
    taskId,
    userId: assigneeId,
    assignedBy: userId,
    assignedAt: timestamp,
    GSI1PK: `USER#${assigneeId}`,
    GSI1SK: `TASK#${taskId}`
  };

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: assignment,
    ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
  }));

  await publishEvent('TaskAssigned', {
    taskId,
    taskTitle: task.Item.title,
    assignedTo: assigneeId,
    assignedBy: userId
  });

  // Return enriched task with assignees
  return await enrichTaskWithAssignees(task.Item);
}

async function listTasks(args, userId, isAdmin) {
  let result;

  if (args.sprintId) {
    result = await ddb.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI3',
      KeyConditionExpression: 'GSI3PK = :sprintId',
      ExpressionAttributeValues: { ':sprintId': `SPRINT#${args.sprintId}` },
      Limit: args.limit || 50
    }));
  } else if (args.status) {
    result = await ddb.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :status',
      ExpressionAttributeValues: { ':status': `STATUS#${args.status}` },
      Limit: args.limit || 50
    }));
  } else if (!isAdmin) {
    result = await ddb.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :userId',
      ExpressionAttributeValues: { ':userId': `USER#${userId}` },
      Limit: args.limit || 50
    }));
  } else {
    result = await ddb.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :status',
      ExpressionAttributeValues: { ':status': 'STATUS#OPEN' },
      Limit: args.limit || 50
    }));
  }

  return {
    items: result.Items || [],
    nextToken: result.LastEvaluatedKey ? JSON.stringify(result.LastEvaluatedKey) : null,
    total: result.Count !== undefined ? result.Count : 0
  };
}

async function createProject(input, userId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can create projects');
  }

  const projectId = uuidv4();
  const timestamp = new Date().toISOString();

  const project = {
    PK: `PROJECT#${projectId}`,
    SK: 'METADATA',
    EntityType: 'PROJECT',
    projectId,
    name: input.name,
    description: input.description || '',
    key: input.key,
    leadId: input.leadId,
    status: 'ACTIVE',
    createdAt: timestamp,
    updatedAt: timestamp
  };

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: project
  }));

  return project;
}

async function createSprint(input, userId, isAdmin) {
  if (!isAdmin) {
    throw new Error('Only admins can create sprints');
  }

  const sprintId = uuidv4();
  const timestamp = new Date().toISOString();

  const sprint = {
    PK: `SPRINT#${sprintId}`,
    SK: 'METADATA',
    EntityType: 'SPRINT',
    sprintId,
    projectId: input.projectId,
    name: input.name,
    goal: input.goal || '',
    startDate: input.startDate,
    endDate: input.endDate,
    status: 'PLANNED',
    createdAt: timestamp,
    updatedAt: timestamp
  };

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: sprint
  }));

  return sprint;
}

async function addComment(input, userId) {
  const commentId = uuidv4();
  const timestamp = new Date().toISOString();

  const comment = {
    PK: `TASK#${input.taskId}`,
    SK: `COMMENT#${commentId}`,
    EntityType: 'COMMENT',
    commentId,
    taskId: input.taskId,
    authorId: userId,
    content: input.content,
    mentions: input.mentions || [],
    createdAt: timestamp,
    updatedAt: timestamp
  };

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: comment
  }));

  await publishEvent('CommentAdded', {
    taskId: input.taskId,
    commentId,
    authorId: userId,
    mentions: input.mentions
  });

  return comment;
}

async function getMyTasks(userId, status) {
  const result = await ddb.send(new QueryCommand({
    TableName: TABLE_NAME,
    IndexName: 'GSI1',
    KeyConditionExpression: 'GSI1PK = :userId',
    ExpressionAttributeValues: { ':userId': `USER#${userId}` }
  }));

  const taskIds = result.Items.map(item => item.taskId);
  const tasks = await Promise.all(
    taskIds.map(async (taskId) => {
      const task = await ddb.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { PK: `TASK#${taskId}`, SK: 'METADATA' }
      }));
      return task.Item;
    })
  );

  return tasks.filter(task => task && (!status || task.status === status));
}

async function publishEvent(detailType, detail) {
  await eventBridge.send(new PutEventsCommand({
    Entries: [{
      Source: 'task-manager.appsync',
      DetailType: detailType,
      Detail: JSON.stringify(detail),
      EventBusName: EVENT_BUS_NAME
    }]
  }));
}
