const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { CognitoIdentityProviderClient, AdminGetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');

const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client);
const snsClient = new SNSClient({});
const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION_NAME });

const TABLE_NAME = process.env.TABLE_NAME;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;
const USER_POOL_ID = process.env.USER_POOL_ID;

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    const eventType = event['detail-type'];
    const detail = event.detail;

    console.log(`Processing ${eventType} event`);

    switch (eventType) {
      case 'TaskAssigned':
        await handleTaskAssigned(detail);
        break;
      case 'TaskStatusUpdated':
        await handleTaskStatusUpdated(detail);
        break;
      case 'TaskClosed':
        await handleTaskClosed(detail);
        break;
      default:
        console.log(`Unknown event type: ${eventType}`);
    }

    return { statusCode: 200, body: 'Success' };
  } catch (error) {
    console.error('Error processing event:', error);
    throw error;
  }
};

async function handleTaskAssigned(detail) {
  const { taskId, taskTitle, assignedTo, assignedBy, priority } = detail;

  const userEmail = await getUserEmail(assignedTo);
  if (!userEmail) {
    console.log(`User ${assignedTo} not found, skipping notification`);
    return;
  }

  const adminEmail = await getUserEmail(assignedBy);
  const adminName = adminEmail || 'Admin';

  await sendNotification(
    userEmail,
    `New Task Assigned: ${taskTitle}`,
    `You have been assigned a new task:\n\nTask: ${taskTitle}\nPriority: ${priority}\nAssigned by: ${adminName}`
  );
}

async function handleTaskStatusUpdated(detail) {
  const { taskId, taskTitle, previousStatus, newStatus, updatedBy } = detail;

  const assignments = await getAssignments(taskId);

  const task = await ddb.send(new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: `TASK#${taskId}`, SK: 'METADATA' }
  }));
  const adminUserId = task.Item?.createdBy;

  const recipients = new Set();
  if (adminUserId) recipients.add(adminUserId);
  
  for (const assignment of assignments) {
    recipients.add(assignment.userId);
  }

  const updaterEmail = await getUserEmail(updatedBy);
  const updaterName = updaterEmail || 'User';

  for (const userId of recipients) {
    const userEmail = await getUserEmail(userId);
    
    if (!userEmail) {
      console.log(`User ${userId} not found, skipping notification`);
      continue;
    }

    await sendNotification(
      userEmail,
      `Task Status Updated: ${taskTitle}`,
      `Task status has been updated:\n\nTask: ${taskTitle}\nPrevious Status: ${previousStatus}\nNew Status: ${newStatus}\nUpdated by: ${updaterName}`
    );
  }
}

async function handleTaskClosed(detail) {
  const { taskId, taskTitle, closedBy, finalStatus } = detail;

  const assignments = await getAssignments(taskId);

  const adminEmail = await getUserEmail(closedBy);
  const adminName = adminEmail || 'Admin';

  for (const assignment of assignments) {
    const userEmail = await getUserEmail(assignment.userId);
    
    if (!userEmail) {
      console.log(`User ${assignment.userId} not found, skipping notification`);
      continue;
    }

    await sendNotification(
      userEmail,
      `Task Closed: ${taskTitle}`,
      `A task you were assigned to has been closed:\n\nTask: ${taskTitle}\nFinal Status: ${finalStatus}\nClosed by: ${adminName}`
    );
  }
}

async function getAssignments(taskId) {
  const result = await ddb.send(new QueryCommand({
    TableName: TABLE_NAME,
    KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :assignment)',
    ExpressionAttributeValues: {
      ':taskId': `TASK#${taskId}`,
      ':assignment': 'ASSIGNMENT#'
    }
  }));
  return result.Items || [];
}

async function getUserEmail(userId) {
  try {
    const command = new AdminGetUserCommand({
      UserPoolId: USER_POOL_ID,
      Username: userId
    });
    
    const response = await cognitoClient.send(command);
    const emailAttr = response.UserAttributes.find(attr => attr.Name === 'email');
    return emailAttr?.Value;
  } catch (error) {
    console.error(`Error fetching user ${userId}:`, error);
    return null;
  }
}

async function sendNotification(userEmail, subject, message) {
  await snsClient.send(new PublishCommand({
    TopicArn: SNS_TOPIC_ARN,
    Subject: subject,
    Message: message,
    MessageAttributes: {
      email: {
        DataType: 'String',
        StringValue: userEmail
      }
    }
  }));
  console.log(`Notification sent for ${userEmail}`);
}
