#!/usr/bin/env node

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'task-manager-sandbox-tasks';

async function testAccessPatterns() {
  console.log('Testing DynamoDB Access Patterns...\n');

  try {
    // Pattern 1: Get Task by ID
    console.log('1️⃣  Pattern 1: Get Task by ID');
    const task = await docClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: 'TASK#task-001', SK: 'METADATA' }
    }));
    console.log(`   Result: ${task.Item ? task.Item.Title : 'Not found'}`);
    console.log(`   ✓ Single item read - O(1)\n`);

    // Pattern 2: Get User Profile
    console.log('2️⃣  Pattern 2: Get User Profile');
    const user = await docClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: 'USER#member-001', SK: 'PROFILE' }
    }));
    console.log(`   Result: ${user.Item ? user.Item.Email : 'Not found'}`);
    console.log(`   ✓ Single item read - O(1)\n`);

    // Pattern 3: Get All Assignments for a Task
    console.log('3️⃣  Pattern 3: Get All Assignments for a Task');
    const assignments = await docClient.send(new QueryCommand({
      TableName: TABLE_NAME,
      KeyConditionExpression: 'PK = :taskId AND begins_with(SK, :assignment)',
      ExpressionAttributeValues: {
        ':taskId': 'TASK#task-001',
        ':assignment': 'ASSIGNMENT#'
      }
    }));
    console.log(`   Result: ${assignments.Items.length} assignment(s)`);
    console.log(`   ✓ Query with begins_with - O(n)\n`);

    // Pattern 4: Get All Tasks Assigned to a User (GSI1)
    console.log('4️⃣  Pattern 4: Get User\'s Assigned Tasks (GSI1)');
    const userTasks = await docClient.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI1',
      KeyConditionExpression: 'GSI1PK = :userId',
      ExpressionAttributeValues: {
        ':userId': 'USER#member-001'
      }
    }));
    console.log(`   Result: ${userTasks.Items.length} task(s) assigned`);
    console.log(`   ✓ GSI query - No table scan\n`);

    // Pattern 5: Get Tasks by Status (GSI2)
    console.log('5️⃣  Pattern 5: Get Tasks by Status (GSI2)');
    const openTasks = await docClient.send(new QueryCommand({
      TableName: TABLE_NAME,
      IndexName: 'GSI2',
      KeyConditionExpression: 'GSI2PK = :status',
      ExpressionAttributeValues: {
        ':status': 'STATUS#OPEN'
      }
    }));
    console.log(`   Result: ${openTasks.Items.length} open task(s)`);
    console.log(`   ✓ GSI query with status filter\n`);

    // Pattern 6: Check if User is Assigned to Task
    console.log('6️⃣  Pattern 6: Check Assignment Exists');
    const checkAssignment = await docClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { PK: 'TASK#task-001', SK: 'ASSIGNMENT#member-001' }
    }));
    console.log(`   Result: ${checkAssignment.Item ? 'Assigned' : 'Not assigned'}`);
    console.log(`   ✓ Single item read for validation\n`);

    console.log('✅ All access patterns tested successfully!');
    console.log('\n📊 Performance Summary:');
    console.log('   - All queries use primary key or GSI');
    console.log('   - No full table scans required');
    console.log('   - Efficient O(1) or O(n) complexity');

  } catch (error) {
    console.error('Error testing access patterns:', error);
    process.exit(1);
  }
}

testAccessPatterns();
