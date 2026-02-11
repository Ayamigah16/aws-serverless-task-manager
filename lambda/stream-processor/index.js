const { Client } = require('@opensearch-project/opensearch');
const { defaultProvider } = require('@aws-sdk/credential-provider-node');
const aws4 = require('aws4');

const OPENSEARCH_ENDPOINT = process.env.OPENSEARCH_ENDPOINT;
const AWS_REGION = process.env.AWS_REGION || 'us-east-1';

const client = new Client({
  node: OPENSEARCH_ENDPOINT,
  Connection: class extends require('@opensearch-project/opensearch').Connection {
    buildRequestObject(params) {
      const request = super.buildRequestObject(params);
      request.service = 'aoss';
      request.region = AWS_REGION;
      request.headers = request.headers || {};
      request.headers['host'] = new URL(OPENSEARCH_ENDPOINT).hostname;
      return aws4.sign(request, defaultProvider());
    }
  }
});

exports.handler = async (event) => {
  console.log('Stream Event:', JSON.stringify(event, null, 2));

  const operations = [];

  for (const record of event.Records) {
    const { eventName, dynamodb } = record;

    if (eventName === 'INSERT' || eventName === 'MODIFY') {
      const newImage = unmarshall(dynamodb.NewImage);
      
      if (newImage.EntityType === 'TASK' && newImage.SK === 'METADATA') {
        operations.push(indexTask(newImage));
      } else if (newImage.EntityType === 'COMMENT') {
        operations.push(indexComment(newImage));
      } else if (newImage.EntityType === 'PROJECT') {
        operations.push(indexProject(newImage));
      }
    } else if (eventName === 'REMOVE') {
      const oldImage = unmarshall(dynamodb.OldImage);
      
      if (oldImage.EntityType === 'TASK') {
        operations.push(deleteTask(oldImage.taskId));
      } else if (oldImage.EntityType === 'COMMENT') {
        operations.push(deleteComment(oldImage.commentId));
      }
    }
  }

  await Promise.all(operations);
  console.log(`Processed ${operations.length} operations`);
};

async function indexTask(task) {
  const document = {
    taskId: task.taskId,
    title: task.title,
    description: task.description || '',
    status: task.status,
    priority: task.priority,
    projectId: task.projectId,
    sprintId: task.sprintId,
    labels: task.labels || [],
    createdBy: task.createdBy,
    createdAt: task.createdAt,
    updatedAt: task.updatedAt,
    dueDate: task.dueDate,
    estimatedPoints: task.estimatedPoints,
    gitBranch: task.gitBranch,
    prUrl: task.prUrl
  };

  try {
    await client.index({
      index: 'tasks',
      id: task.taskId,
      body: document,
      refresh: true
    });
    console.log(`Indexed task: ${task.taskId}`);
  } catch (error) {
    console.error(`Error indexing task ${task.taskId}:`, error);
    throw error;
  }
}

async function indexComment(comment) {
  const document = {
    commentId: comment.commentId,
    taskId: comment.taskId,
    authorId: comment.authorId,
    content: comment.content,
    mentions: comment.mentions || [],
    createdAt: comment.createdAt
  };

  try {
    await client.index({
      index: 'comments',
      id: comment.commentId,
      body: document,
      refresh: true
    });
    console.log(`Indexed comment: ${comment.commentId}`);
  } catch (error) {
    console.error(`Error indexing comment ${comment.commentId}:`, error);
    throw error;
  }
}

async function indexProject(project) {
  const document = {
    projectId: project.projectId,
    name: project.name,
    description: project.description || '',
    key: project.key,
    status: project.status,
    createdAt: project.createdAt
  };

  try {
    await client.index({
      index: 'projects',
      id: project.projectId,
      body: document,
      refresh: true
    });
    console.log(`Indexed project: ${project.projectId}`);
  } catch (error) {
    console.error(`Error indexing project ${project.projectId}:`, error);
    throw error;
  }
}

async function deleteTask(taskId) {
  try {
    await client.delete({
      index: 'tasks',
      id: taskId
    });
    console.log(`Deleted task from index: ${taskId}`);
  } catch (error) {
    if (error.meta?.statusCode !== 404) {
      console.error(`Error deleting task ${taskId}:`, error);
      throw error;
    }
  }
}

async function deleteComment(commentId) {
  try {
    await client.delete({
      index: 'comments',
      id: commentId
    });
    console.log(`Deleted comment from index: ${commentId}`);
  } catch (error) {
    if (error.meta?.statusCode !== 404) {
      console.error(`Error deleting comment ${commentId}:`, error);
      throw error;
    }
  }
}

function unmarshall(data) {
  const result = {};
  for (const [key, value] of Object.entries(data)) {
    if (value.S) result[key] = value.S;
    else if (value.N) result[key] = Number(value.N);
    else if (value.BOOL) result[key] = value.BOOL;
    else if (value.L) result[key] = value.L.map(item => unmarshall({ item }).item);
    else if (value.M) result[key] = unmarshall(value.M);
    else if (value.NULL) result[key] = null;
  }
  return result;
}
