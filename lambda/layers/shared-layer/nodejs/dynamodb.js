const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, QueryCommand, DeleteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME;

async function getItem(pk, sk) {
  const params = {
    TableName: TABLE_NAME,
    Key: { PK: pk, SK: sk }
  };

  const result = await docClient.send(new GetCommand(params));
  return result.Item;
}

async function putItem(item, conditionExpression = null) {
  const params = {
    TableName: TABLE_NAME,
    Item: item
  };

  if (conditionExpression) {
    params.ConditionExpression = conditionExpression;
  }

  await docClient.send(new PutCommand(params));
}

async function updateItem(pk, sk, updateExpression, expressionAttributeValues, expressionAttributeNames = null) {
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

  const result = await docClient.send(new UpdateCommand(params));
  return result.Attributes;
}

async function query(params) {
  params.TableName = TABLE_NAME;
  const result = await docClient.send(new QueryCommand(params));
  return result.Items || [];
}

async function deleteItem(pk, sk) {
  const params = {
    TableName: TABLE_NAME,
    Key: { PK: pk, SK: sk }
  };

  await docClient.send(new DeleteCommand(params));
}

module.exports = {
  getItem,
  putItem,
  updateItem,
  query,
  deleteItem
};
