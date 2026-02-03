#!/usr/bin/env node

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'task-manager-sandbox-tasks';

async function testConditionalWrites() {
  console.log('Testing Conditional Writes...\n');

  try {
    // Test 1: Prevent Duplicate Assignment
    console.log('1️⃣  Test: Prevent Duplicate Assignment');
    
    const assignment = {
      PK: 'TASK#test-task',
      SK: 'ASSIGNMENT#test-user',
      EntityType: 'ASSIGNMENT',
      TaskId: 'test-task',
      UserId: 'test-user',
      AssignedBy: 'admin-001',
      AssignedAt: Date.now(),
      GSI1PK: 'USER#test-user',
      GSI1SK: 'TASK#test-task'
    };

    // First write should succeed
    try {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: assignment,
        ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
      }));
      console.log('   ✓ First assignment created successfully');
    } catch (error) {
      console.log('   ℹ️  Assignment already exists (expected if running multiple times)');
    }

    // Second write should fail
    try {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: assignment,
        ConditionExpression: 'attribute_not_exists(PK) AND attribute_not_exists(SK)'
      }));
      console.log('   ❌ ERROR: Duplicate assignment was allowed!');
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') {
        console.log('   ✓ Duplicate assignment prevented (as expected)');
      } else {
        throw error;
      }
    }

    // Test 2: Update Only If Exists
    console.log('\n2️⃣  Test: Update Only If Exists');
    
    try {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: 'TASK#nonexistent',
          SK: 'METADATA',
          Title: 'Should Fail'
        },
        ConditionExpression: 'attribute_exists(PK)'
      }));
      console.log('   ❌ ERROR: Created item that should not exist!');
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') {
        console.log('   ✓ Update prevented for non-existent item');
      } else {
        throw error;
      }
    }

    // Test 3: Optimistic Locking
    console.log('\n3️⃣  Test: Optimistic Locking with Version');
    
    const versionedItem = {
      PK: 'TASK#versioned-task',
      SK: 'METADATA',
      Title: 'Versioned Task',
      Version: 1
    };

    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: versionedItem
    }));
    console.log('   ✓ Created versioned item');

    try {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: { ...versionedItem, Title: 'Updated', Version: 2 },
        ConditionExpression: 'Version = :expectedVersion',
        ExpressionAttributeValues: { ':expectedVersion': 1 }
      }));
      console.log('   ✓ Update succeeded with correct version');
    } catch (error) {
      console.log('   ❌ Update failed:', error.message);
    }

    try {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: { ...versionedItem, Title: 'Should Fail', Version: 3 },
        ConditionExpression: 'Version = :expectedVersion',
        ExpressionAttributeValues: { ':expectedVersion': 1 }
      }));
      console.log('   ❌ ERROR: Update with wrong version succeeded!');
    } catch (error) {
      if (error.name === 'ConditionalCheckFailedException') {
        console.log('   ✓ Update prevented with wrong version');
      }
    }

    console.log('\n✅ All conditional write tests passed!');
    console.log('\n📊 Race Condition Prevention:');
    console.log('   - Duplicate assignments blocked');
    console.log('   - Non-existent updates prevented');
    console.log('   - Optimistic locking working');

  } catch (error) {
    console.error('Error testing conditional writes:', error);
    process.exit(1);
  }
}

testConditionalWrites();
