const { getItem, query } = require('/opt/nodejs/dynamodb');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const { CognitoIdentityProviderClient, AdminGetUserCommand } = require('@aws-sdk/client-cognito-identity-provider');

const sesClient = new SESClient({});
const cognitoClient = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION_NAME });
const SENDER_EMAIL = process.env.SENDER_EMAIL;
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

  await sendEmail(
    userEmail,
    `New Task Assigned: ${taskTitle}`,
    `Hi,\n\nYou have been assigned a new task:\n\nTask: ${taskTitle}\nPriority: ${priority}\nAssigned by: ${adminName}\n\nPlease log in to view details and update the status.\n\nBest regards,\nTask Management System`
  );
}

async function handleTaskStatusUpdated(detail) {
  const { taskId, taskTitle, previousStatus, newStatus, updatedBy } = detail;

  const assignments = await query({
    KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :assignment)',
    ExpressionAttributeValues: {
      ':taskId': `TASK#${taskId}`,
      ':assignment': 'ASSIGNMENT#'
    }
  });

  const task = await getItem(`TASK#${taskId}`, 'METADATA');
  const adminUserId = task?.CreatedBy;

  const recipients = new Set();
  if (adminUserId) recipients.add(adminUserId);
  
  for (const assignment of assignments) {
    recipients.add(assignment.UserId);
  }

  const updaterEmail = await getUserEmail(updatedBy);
  const updaterName = updaterEmail || 'User';

  for (const userId of recipients) {
    const userEmail = await getUserEmail(userId);
    
    if (!userEmail) {
      console.log(`User ${userId} not found, skipping notification`);
      continue;
    }

    await sendEmail(
      userEmail,
      `Task Status Updated: ${taskTitle}`,
      `Hi,\n\nTask status has been updated:\n\nTask: ${taskTitle}\nPrevious Status: ${previousStatus}\nNew Status: ${newStatus}\nUpdated by: ${updaterName}\n\nLog in to view full details.\n\nBest regards,\nTask Management System`
    );
  }
}

async function handleTaskClosed(detail) {
  const { taskId, taskTitle, closedBy, finalStatus } = detail;

  const assignments = await query({
    KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :assignment)',
    ExpressionAttributeValues: {
      ':taskId': `TASK#${taskId}`,
      ':assignment': 'ASSIGNMENT#'
    }
  });

  const adminEmail = await getUserEmail(closedBy);
  const adminName = adminEmail || 'Admin';

  for (const assignment of assignments) {
    const userEmail = await getUserEmail(assignment.UserId);
    
    if (!userEmail) {
      console.log(`User ${assignment.UserId} not found, skipping notification`);
      continue;
    }

    await sendEmail(
      userEmail,
      `Task Closed: ${taskTitle}`,
      `Hi,\n\nA task you were assigned to has been closed:\n\nTask: ${taskTitle}\nFinal Status: ${finalStatus}\nClosed by: ${adminName}\n\nThank you for your contribution.\n\nBest regards,\nTask Management System`
    );
  }
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

async function sendEmail(to, subject, body) {
  const params = {
    Source: SENDER_EMAIL,
    Destination: {
      ToAddresses: [to]
    },
    Message: {
      Subject: {
        Data: subject,
        Charset: 'UTF-8'
      },
      Body: {
        Text: {
          Data: body,
          Charset: 'UTF-8'
        }
      }
    }
  };

  try {
    const result = await sesClient.send(new SendEmailCommand(params));
    console.log(`Email sent to ${to}, MessageId: ${result.MessageId}`);
    return result;
  } catch (error) {
    console.error(`Failed to send email to ${to}:`, error);
    throw error;
  }
}
