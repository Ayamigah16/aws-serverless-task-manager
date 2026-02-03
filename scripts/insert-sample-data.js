#!/usr/bin/env node

const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, BatchWriteCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'task-manager-sandbox-tasks';

const sampleData = {
  users: [
    {
      PK: 'USER#admin-001',
      SK: 'PROFILE',
      EntityType: 'USER',
      UserId: 'admin-001',
      Email: 'admin@amalitech.com',
      UserStatus: 'ACTIVE',
      Groups: ['Admins'],
      CreatedAt: Date.now()
    },
    {
      PK: 'USER#member-001',
      SK: 'PROFILE',
      EntityType: 'USER',
      UserId: 'member-001',
      Email: 'john.doe@amalitech.com',
      UserStatus: 'ACTIVE',
      Groups: ['Members'],
      CreatedAt: Date.now()
    },
    {
      PK: 'USER#member-002',
      SK: 'PROFILE',
      EntityType: 'USER',
      UserId: 'member-002',
      Email: 'jane.smith@amalitechtraining.org',
      UserStatus: 'ACTIVE',
      Groups: ['Members'],
      CreatedAt: Date.now()
    }
  ],
  tasks: [
    {
      PK: 'TASK#task-001',
      SK: 'METADATA',
      EntityType: 'TASK',
      TaskId: 'task-001',
      Title: 'Setup AWS Infrastructure',
      Description: 'Deploy Terraform infrastructure to AWS sandbox account',
      Priority: 'HIGH',
      Status: 'OPEN',
      CreatedBy: 'admin-001',
      CreatedAt: Date.now(),
      UpdatedAt: Date.now(),
      GSI2PK: 'STATUS#OPEN',
      GSI2SK: `CREATED_AT#${Date.now()}`
    },
    {
      PK: 'TASK#task-002',
      SK: 'METADATA',
      EntityType: 'TASK',
      TaskId: 'task-002',
      Title: 'Implement Lambda Functions',
      Description: 'Complete Task API and Notification Handler implementations',
      Priority: 'HIGH',
      Status: 'IN_PROGRESS',
      CreatedBy: 'admin-001',
      CreatedAt: Date.now() - 86400000,
      UpdatedAt: Date.now(),
      GSI2PK: 'STATUS#IN_PROGRESS',
      GSI2SK: `CREATED_AT#${Date.now() - 86400000}`
    },
    {
      PK: 'TASK#task-003',
      SK: 'METADATA',
      EntityType: 'TASK',
      TaskId: 'task-003',
      Title: 'Build React Frontend',
      Description: 'Create React application with Amplify integration',
      Priority: 'MEDIUM',
      Status: 'OPEN',
      CreatedBy: 'admin-001',
      CreatedAt: Date.now() - 172800000,
      UpdatedAt: Date.now() - 172800000,
      GSI2PK: 'STATUS#OPEN',
      GSI2SK: `CREATED_AT#${Date.now() - 172800000}`
    }
  ],
  assignments: [
    {
      PK: 'TASK#task-001',
      SK: 'ASSIGNMENT#member-001',
      EntityType: 'ASSIGNMENT',
      TaskId: 'task-001',
      UserId: 'member-001',
      AssignedBy: 'admin-001',
      AssignedAt: Date.now(),
      GSI1PK: 'USER#member-001',
      GSI1SK: 'TASK#task-001'
    },
    {
      PK: 'TASK#task-002',
      SK: 'ASSIGNMENT#member-002',
      EntityType: 'ASSIGNMENT',
      TaskId: 'task-002',
      UserId: 'member-002',
      AssignedBy: 'admin-001',
      AssignedAt: Date.now() - 86400000,
      GSI1PK: 'USER#member-002',
      GSI1SK: 'TASK#task-002'
    },
    {
      PK: 'TASK#task-003',
      SK: 'ASSIGNMENT#member-001',
      EntityType: 'ASSIGNMENT',
      TaskId: 'task-003',
      UserId: 'member-001',
      AssignedBy: 'admin-001',
      AssignedAt: Date.now() - 172800000,
      GSI1PK: 'USER#member-001',
      GSI1SK: 'TASK#task-003'
    }
  ]
};

async function insertSampleData() {
  console.log('Inserting sample data into DynamoDB...');
  console.log(`Table: ${TABLE_NAME}\n`);

  try {
    // Insert users
    console.log('Inserting users...');
    for (const user of sampleData.users) {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: user
      }));
      console.log(`✓ User: ${user.Email}`);
    }

    // Insert tasks
    console.log('\nInserting tasks...');
    for (const task of sampleData.tasks) {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: task
      }));
      console.log(`✓ Task: ${task.Title}`);
    }

    // Insert assignments
    console.log('\nInserting assignments...');
    for (const assignment of sampleData.assignments) {
      await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: assignment
      }));
      console.log(`✓ Assignment: ${assignment.TaskId} → ${assignment.UserId}`);
    }

    console.log('\n✅ Sample data inserted successfully!');
    console.log(`\nSummary:`);
    console.log(`- Users: ${sampleData.users.length}`);
    console.log(`- Tasks: ${sampleData.tasks.length}`);
    console.log(`- Assignments: ${sampleData.assignments.length}`);
  } catch (error) {
    console.error('Error inserting sample data:', error);
    process.exit(1);
  }
}

insertSampleData();
