const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME;

async function getItem(pk, sk) {
  const command = new GetCommand({
    TableName: TABLE_NAME,
    Key: { PK: pk, SK: sk }
  });
  const response = await docClient.send(command);
  return response.Item;
}

async function putItem(item, conditionExpression) {
  const params = {
    TableName: TABLE_NAME,
    Item: item
  };
  
  if (conditionExpression) {
    params.ConditionExpression = conditionExpression;
  }
  
  const command = new PutCommand(params);
  await docClient.send(command);
  return item;
}

async function updateItem(pk, sk, updateExpression, expressionAttributeValues, expressionAttributeNames) {
  const params = {
    TableName: TABLE_NAME,
    Key: { PK: pk, SK: sk },
    UpdateExpression: updateExpression,
    ExpressionAttributeValues: expressionAttributeValues,
    ReturnValues: 'ALL_NEW'
  };
  
  if (expressionAttributeNames) {
    params.ExpressionAttributeNames = expressionAttributeNames;
  }
  
  const command = new UpdateCommand(params);
  const response = await docClient.send(command);
  return response.Attributes;
}

async function query(params) {
  const command = new QueryCommand({
    TableName: TABLE_NAME,
    ...params
  });
  const response = await docClient.send(command);
  return response.Items || [];
}

async function deleteItem(pk, sk) {
  const command = new DeleteCommand({
    TableName: TABLE_NAME,
    Key: { PK: pk, SK: sk }
  });
  await docClient.send(command);
}

module.exports = {
  getItem,
  putItem,
  updateItem,
  query,
  deleteItem
};
