const { getItem, query } = require('/opt/nodejs/dynamodb');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');

const sesClient = new SESClient({});
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'noreply@amalitech.com';

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

  const user = await getItem(`USER#${assignedTo}`, 'PROFILE');
  
  if (!user || user.UserStatus === 'DEACTIVATED') {
    console.log(`User ${assignedTo} is deactivated or not found, skipping notification`);
    return;
  }

  const admin = await getItem(`USER#${assignedBy}`, 'PROFILE');
  const adminName = admin?.Email || 'Admin';

  await sendEmail(
    user.Email,
    `New Task Assigned: ${taskTitle}`,
    `Hi ${user.Email},\n\nYou have been assigned a new task:\n\nTask: ${taskTitle}\nPriority: ${priority}\nAssigned by: ${adminName}\n\nPlease log in to view details and update the status.\n\nBest regards,\nTask Management System`
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

  const updater = await getItem(`USER#${updatedBy}`, 'PROFILE');
  const updaterName = updater?.Email || 'User';

  for (const userId of recipients) {
    const user = await getItem(`USER#${userId}`, 'PROFILE');
    
    if (!user || user.UserStatus === 'DEACTIVATED') {
      console.log(`User ${userId} is deactivated or not found, skipping notification`);
      continue;
    }

    await sendEmail(
      user.Email,
      `Task Status Updated: ${taskTitle}`,
      `Hi ${user.Email},\n\nTask status has been updated:\n\nTask: ${taskTitle}\nPrevious Status: ${previousStatus}\nNew Status: ${newStatus}\nUpdated by: ${updaterName}\n\nLog in to view full details.\n\nBest regards,\nTask Management System`
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

  const admin = await getItem(`USER#${closedBy}`, 'PROFILE');
  const adminName = admin?.Email || 'Admin';

  for (const assignment of assignments) {
    const user = await getItem(`USER#${assignment.UserId}`, 'PROFILE');
    
    if (!user || user.UserStatus === 'DEACTIVATED') {
      console.log(`User ${assignment.UserId} is deactivated, skipping notification`);
      continue;
    }

    await sendEmail(
      user.Email,
      `Task Closed: ${taskTitle}`,
      `Hi ${user.Email},\n\nA task you were assigned to has been closed:\n\nTask: ${taskTitle}\nFinal Status: ${finalStatus}\nClosed by: ${adminName}\n\nThank you for your contribution.\n\nBest regards,\nTask Management System`
    );
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
