const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, UpdateCommand } = require('@aws-sdk/lib-dynamodb');
const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');
const crypto = require('crypto');

const ddbClient = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(ddbClient);
const eventBridge = new EventBridgeClient({});

const TABLE_NAME = process.env.TABLE_NAME;
const EVENT_BUS_NAME = process.env.EVENT_BUS_NAME;
const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET;

exports.handler = async (event) => {
  console.log('GitHub Webhook Event:', JSON.stringify(event, null, 2));

  // Verify webhook signature
  const signature = event.headers['x-hub-signature-256'];
  const body = event.body;
  
  if (!verifySignature(body, signature)) {
    return {
      statusCode: 401,
      body: JSON.stringify({ error: 'Invalid signature' })
    };
  }

  const payload = JSON.parse(body);
  const eventType = event.headers['x-github-event'];

  try {
    switch (eventType) {
      case 'push':
        await handlePushEvent(payload);
        break;
      case 'pull_request':
        await handlePullRequestEvent(payload);
        break;
      case 'pull_request_review':
        await handlePullRequestReview(payload);
        break;
      default:
        console.log(`Unhandled event type: ${eventType}`);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Webhook processed successfully' })
    };
  } catch (error) {
    console.error('Error processing webhook:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};

function verifySignature(body, signature) {
  if (!WEBHOOK_SECRET || !signature) {
    return false;
  }

  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  const digest = 'sha256=' + hmac.update(body).digest('hex');
  
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(digest)
  );
}

async function handlePushEvent(payload) {
  const { commits, ref, repository } = payload;
  const branch = ref.replace('refs/heads/', '');

  for (const commit of commits) {
    const message = commit.message;
    const taskIds = extractTaskIds(message);

    for (const taskId of taskIds) {
      // Update task with commit info
      await updateTaskWithCommit(taskId, {
        commitSha: commit.id,
        commitMessage: message,
        commitAuthor: commit.author.name,
        commitUrl: commit.url,
        branch,
        repository: repository.full_name
      });

      // Check for status keywords in commit message
      const status = extractStatusFromMessage(message);
      if (status) {
        await updateTaskStatus(taskId, status, commit.author.name);
      }
    }
  }
}

async function handlePullRequestEvent(payload) {
  const { action, pull_request } = payload;
  const taskIds = extractTaskIds(pull_request.title + ' ' + pull_request.body);

  for (const taskId of taskIds) {
    const updates = {
      prNumber: pull_request.number,
      prTitle: pull_request.title,
      prUrl: pull_request.html_url,
      prStatus: pull_request.state,
      gitBranch: pull_request.head.ref
    };

    await updateTaskWithPR(taskId, updates);

    // Update task status based on PR action
    if (action === 'opened') {
      await updateTaskStatus(taskId, 'IN_REVIEW', pull_request.user.login);
    } else if (action === 'closed' && pull_request.merged) {
      await updateTaskStatus(taskId, 'COMPLETED', pull_request.user.login);
    }

    // Publish event
    await publishEvent('TaskUpdatedFromGitHub', {
      taskId,
      action,
      prNumber: pull_request.number,
      prUrl: pull_request.html_url
    });
  }
}

async function handlePullRequestReview(payload) {
  const { action, review, pull_request } = payload;
  
  if (action === 'submitted' && review.state === 'approved') {
    const taskIds = extractTaskIds(pull_request.title + ' ' + pull_request.body);
    
    for (const taskId of taskIds) {
      await publishEvent('TaskPRApproved', {
        taskId,
        prNumber: pull_request.number,
        reviewer: review.user.login
      });
    }
  }
}

async function updateTaskWithCommit(taskId, commitInfo) {
  try {
    await ddb.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TASK#${taskId}`, SK: 'METADATA' },
      UpdateExpression: 'SET lastCommit = :commit, gitBranch = :branch, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':commit': commitInfo,
        ':branch': commitInfo.branch,
        ':updatedAt': new Date().toISOString()
      }
    }));
    console.log(`Updated task ${taskId} with commit info`);
  } catch (error) {
    console.error(`Error updating task ${taskId}:`, error);
  }
}

async function updateTaskWithPR(taskId, prInfo) {
  try {
    await ddb.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TASK#${taskId}`, SK: 'METADATA' },
      UpdateExpression: 'SET prUrl = :prUrl, prNumber = :prNumber, prStatus = :prStatus, gitBranch = :branch, updatedAt = :updatedAt',
      ExpressionAttributeValues: {
        ':prUrl': prInfo.prUrl,
        ':prNumber': prInfo.prNumber,
        ':prStatus': prInfo.prStatus,
        ':branch': prInfo.gitBranch,
        ':updatedAt': new Date().toISOString()
      }
    }));
    console.log(`Updated task ${taskId} with PR info`);
  } catch (error) {
    console.error(`Error updating task ${taskId}:`, error);
  }
}

async function updateTaskStatus(taskId, status, updatedBy) {
  try {
    await ddb.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { PK: `TASK#${taskId}`, SK: 'METADATA' },
      UpdateExpression: 'SET #status = :status, updatedAt = :updatedAt, updatedBy = :updatedBy, GSI2PK = :gsi2pk',
      ExpressionAttributeNames: {
        '#status': 'status'
      },
      ExpressionAttributeValues: {
        ':status': status,
        ':updatedAt': new Date().toISOString(),
        ':updatedBy': updatedBy,
        ':gsi2pk': `STATUS#${status}`
      }
    }));
    console.log(`Updated task ${taskId} status to ${status}`);
  } catch (error) {
    console.error(`Error updating task ${taskId} status:`, error);
  }
}

function extractTaskIds(text) {
  // Extract task IDs from text (e.g., TASK-123, #123, TM-456)
  const patterns = [
    /TASK-(\d+)/gi,
    /#(\d+)/g,
    /TM-(\d+)/gi
  ];

  const taskIds = new Set();
  
  for (const pattern of patterns) {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      taskIds.add(match[1]);
    }
  }

  return Array.from(taskIds);
}

function extractStatusFromMessage(message) {
  const lowerMessage = message.toLowerCase();
  
  if (lowerMessage.includes('[completed]') || lowerMessage.includes('fixes') || lowerMessage.includes('closes')) {
    return 'COMPLETED';
  } else if (lowerMessage.includes('[in progress]') || lowerMessage.includes('wip')) {
    return 'IN_PROGRESS';
  } else if (lowerMessage.includes('[blocked]')) {
    return 'BLOCKED';
  }
  
  return null;
}

async function publishEvent(detailType, detail) {
  await eventBridge.send(new PutEventsCommand({
    Entries: [{
      Source: 'task-manager.github',
      DetailType: detailType,
      Detail: JSON.stringify(detail),
      EventBusName: EVENT_BUS_NAME
    }]
  }));
}
