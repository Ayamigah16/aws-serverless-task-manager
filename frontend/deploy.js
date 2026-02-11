const { AmplifyClient, CreateAppCommand, CreateBranchCommand, UpdateAppCommand, GetAppCommand } = require('@aws-sdk/client-amplify');
const { execSync } = require('child_process');
const { readFileSync } = require('fs');

const client = new AmplifyClient({ region: 'eu-west-1' });

const ENV_VARS = {
  NEXT_PUBLIC_USER_POOL_ID: 'eu-west-1_FfAVO3yNz',
  NEXT_PUBLIC_USER_POOL_CLIENT_ID: '2f0i4se7ksrif4vot3tkp7g1jk',
  NEXT_PUBLIC_APPSYNC_URL: 'https://4yfcosstwzc4zor2pakty7so4y.appsync-api.eu-west-1.amazonaws.com/graphql',
  NEXT_PUBLIC_AWS_REGION: 'eu-west-1'
};

async function deploy() {
  console.log('🚀 Deploying to AWS Amplify...\n');

  try {
    const appId = 'dieb2ukn8mt87';
    
    // Update environment variables
    await client.send(new UpdateAppCommand({
      appId,
      environmentVariables: ENV_VARS
    }));
    console.log('✅ Updated environment variables');

    console.log('\n📋 Next steps:');
    console.log('\n1. Connect GitHub repository:');
    console.log('   - Go to: https://console.aws.amazon.com/amplify/home?region=eu-west-1#/dieb2ukn8mt87');
    console.log('   - Click "Connect branch"');
    console.log('   - Select GitHub and authorize');
    console.log('   - Choose repository and branch');
    console.log('\n2. Or push to trigger deployment:');
    console.log('   git push origin main');
    console.log('\n🌐 App URL: https://main.dieb2ukn8mt87.amplifyapp.com');

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

deploy();
