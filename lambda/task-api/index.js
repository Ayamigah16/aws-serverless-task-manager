const { validateRequest, isAdmin, getUserId } = require('./shared/auth');
const { getItem, putItem, updateItem, query, deleteItem } = require('./shared/dynamodb');
const { publishEvent } = require('./shared/eventbridge');
const { success, error, unauthorized, forbidden, notFound, badRequest, conflict } = require('./shared/response');
const { v4: uuidv4 } = require('uuid');

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    const decoded = await validateRequest(event);
    const userId = getUserId(decoded);
    const userIsAdmin = isAdmin(decoded);

    const path = event.path;
    const method = event.httpMethod;
    const pathParams = event.pathParameters || {};

    // Route requests
    if (method === 'POST' && path === '/tasks') {
      return await createTask(event, userId, userIsAdmin);
    } else if (method === 'GET' && path === '/tasks') {
      return await listTasks(userId, userIsAdmin);
    } else if (method === 'GET' && pathParams.taskId) {
      return await getTask(pathParams.taskId, userId, userIsAdmin);
    } else if (method === 'PUT' && pathParams.taskId && path.includes('/status')) {
      return await updateTaskStatus(pathParams.taskId, event, userId);
    } else if (method === 'PUT' && pathParams.taskId) {
      return await updateTask(pathParams.taskId, event, userIsAdmin);
    } else if (method === 'POST' && path.includes('/assign')) {
      return await assignTask(pathParams.taskId, event, userId, userIsAdmin);
    } else if (method === 'POST' && path.includes('/close')) {
      return await closeTask(pathParams.taskId, userId, userIsAdmin);
    } else if (method === 'DELETE' && pathParams.taskId) {
      return await deleteTask(pathParams.taskId, userIsAdmin);
    }

    return notFound('Endpoint not found');
  } catch (err) {
    console.error('Error:', err);
    if (err.message.includes('authorization')) {
      return unauthorized(err.message);
    }
    return error(err.message);
  }
};

async function createTask(event, userId, userIsAdmin) {
  if (!userIsAdmin) {
    return forbidden('Only admins can create tasks');
  }

  const body = JSON.parse(event.body || '{}');
  const { title, description, priority = 'MEDIUM' } = body;

  if (!title) {
    return badRequest('Title is required');
  }

  const taskId = uuidv4();
  const timestamp = Date.now();

  const task = {
    PK: `TASK#${taskId}`,
    SK: 'METADATA',
    EntityType: 'TASK',
    TaskId: taskId,
    Title: title,
    Description: description || '',
    Priority: priority,
    Status: 'OPEN',
    CreatedBy: userId,
    CreatedAt: timestamp,
    UpdatedAt: timestamp,
    GSI2PK: 'STATUS#OPEN',
    GSI2SK: `CREATED_AT#${timestamp}`
  };

  await putItem(task);

  await publishEvent('TaskCreated', {
    taskId,
    title,
    createdBy: userId,
    priority
  });

  return success({ taskId, ...task }, 201);
}

async function listTasks(userId, userIsAdmin) {
  let tasks;

  if (userIsAdmin) {
    tasks = await query({
      KeyConditionExpression: 'GSI2PK = :status',
      ExpressionAttributeValues: { ':status': 'STATUS#OPEN' },
      IndexName: 'GSI2'
    });
  } else {
    tasks = await query({
      KeyConditionExpression: 'GSI1PK = :userId',
      ExpressionAttributeValues: { ':userId': `USER#${userId}` },
      IndexName: 'GSI1'
    });
  }

  return success({ tasks, count: tasks.length });
}

async function getTask(taskId, userId, userIsAdmin) {
  const task = await getItem(`TASK#${taskId}`, 'METADATA');

  if (!task) {
    return notFound('Task not found');
  }

  if (!userIsAdmin) {
    const assignment = await getItem(`TASK#${taskId}`, `ASSIGNMENT#${userId}`);
    if (!assignment) {
      return forbidden('You are not assigned to this task');
    }
  }

  return success(task);
}

async function updateTask(taskId, event, userIsAdmin) {
  if (!userIsAdmin) {
    return forbidden('Only admins can update tasks');
  }

  const body = JSON.parse(event.body || '{}');
  const { title, description, priority } = body;

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  if (!task) {
    return notFound('Task not found');
  }

  const updates = [];
  const values = { ':updatedAt': Date.now() };

  if (title) {
    updates.push('Title = :title');
    values[':title'] = title;
  }
  if (description !== undefined) {
    updates.push('Description = :description');
    values[':description'] = description;
  }
  if (priority) {
    updates.push('Priority = :priority');
    values[':priority'] = priority;
  }

  updates.push('UpdatedAt = :updatedAt');

  const updated = await updateItem(
    `TASK#${taskId}`,
    'METADATA',
    `SET ${updates.join(', ')}`,
    values
  );

  return success(updated);
}

async function assignTask(taskId, event, userId, userIsAdmin) {
  if (!userIsAdmin) {
    return forbidden('Only admins can assign tasks');
  }

  const body = JSON.parse(event.body || '{}');
  const { assignedTo } = body;

  if (!assignedTo) {
    return badRequest('assignedTo is required');
  }

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  if (!task) {
    return notFound('Task not found');
  }

  const user = await getItem(`USER#${assignedTo}`, 'PROFILE');
  if (!user || user.UserStatus === 'DEACTIVATED') {
    return badRequest('User not found or deactivated');
  }

  try {
    const assignment = {
      PK: `TASK#${taskId}`,
      SK: `ASSIGNMENT#${assignedTo}`,
      EntityType: 'ASSIGNMENT',
      TaskId: taskId,
      UserId: assignedTo,
      AssignedBy: userId,
      AssignedAt: Date.now(),
      GSI1PK: `USER#${assignedTo}`,
      GSI1SK: `TASK#${taskId}`
    };

    await putItem(assignment, 'attribute_not_exists(PK) AND attribute_not_exists(SK)');

    await publishEvent('TaskAssigned', {
      taskId,
      taskTitle: task.Title,
      assignedTo,
      assignedBy: userId,
      priority: task.Priority
    });

    return success({ message: 'Task assigned successfully', assignment });
  } catch (err) {
    if (err.name === 'ConditionalCheckFailedException') {
      return conflict('Task already assigned to this user');
    }
    throw err;
  }
}

async function updateTaskStatus(taskId, event, userId) {
  const body = JSON.parse(event.body || '{}');
  const { status } = body;

  if (!status || !['OPEN', 'IN_PROGRESS', 'COMPLETED'].includes(status)) {
    return badRequest('Valid status is required (OPEN, IN_PROGRESS, COMPLETED)');
  }

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  if (!task) {
    return notFound('Task not found');
  }

  const assignment = await getItem(`TASK#${taskId}`, `ASSIGNMENT#${userId}`);
  if (!assignment) {
    return forbidden('You are not assigned to this task');
  }

  const previousStatus = task.Status;

  const updated = await updateItem(
    `TASK#${taskId}`,
    'METADATA',
    'SET #status = :status, UpdatedAt = :updatedAt, UpdatedBy = :updatedBy, GSI2PK = :gsi2pk',
    {
      ':status': status,
      ':updatedAt': Date.now(),
      ':updatedBy': userId,
      ':gsi2pk': `STATUS#${status}`
    },
    { '#status': 'Status' }
  );

  await publishEvent('TaskStatusUpdated', {
    taskId,
    taskTitle: task.Title,
    previousStatus,
    newStatus: status,
    updatedBy: userId
  });

  return success(updated);
}

async function closeTask(taskId, userId, userIsAdmin) {
  if (!userIsAdmin) {
    return forbidden('Only admins can close tasks');
  }

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  if (!task) {
    return notFound('Task not found');
  }

  const updated = await updateItem(
    `TASK#${taskId}`,
    'METADATA',
    'SET #status = :status, UpdatedAt = :updatedAt, ClosedBy = :closedBy, ClosedAt = :closedAt, GSI2PK = :gsi2pk',
    {
      ':status': 'CLOSED',
      ':updatedAt': Date.now(),
      ':closedBy': userId,
      ':closedAt': Date.now(),
      ':gsi2pk': 'STATUS#CLOSED'
    },
    { '#status': 'Status' }
  );

  await publishEvent('TaskClosed', {
    taskId,
    taskTitle: task.Title,
    closedBy: userId,
    finalStatus: task.Status
  });

  return success(updated);
}

async function deleteTask(taskId, userIsAdmin) {
  if (!userIsAdmin) {
    return forbidden('Only admins can delete tasks');
  }

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  if (!task) {
    return notFound('Task not found');
  }

  await deleteItem(`TASK#${taskId}`, 'METADATA');

  return success({ message: 'Task deleted successfully' });
}
