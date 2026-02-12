const { AmplifyClient, UpdateAppCommand } = require('@aws-sdk/client-amplify');
const { readFileSync } = require('fs');
require('dotenv').config();

// Load configuration from environment variables
const AWS_REGION = process.env.AWS_REGION || process.env.NEXT_PUBLIC_AWS_REGION || 'eu-west-1';
const AMPLIFY_APP_ID = process.env.AMPLIFY_APP_ID;

// Validate required environment variables
if (!AMPLIFY_APP_ID) {
  console.error('❌ Error: AMPLIFY_APP_ID environment variable is required');
  console.error('Set it with: export AMPLIFY_APP_ID=your-app-id');
  process.exit(1);
}

// Environment variables to set in Amplify
// These should be loaded from .env file or environment
const ENV_VARS = {
  NEXT_PUBLIC_AWS_REGION: process.env.NEXT_PUBLIC_AWS_REGION,
  NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL,
  NEXT_PUBLIC_COGNITO_USER_POOL_ID: process.env.NEXT_PUBLIC_COGNITO_USER_POOL_ID,
  NEXT_PUBLIC_COGNITO_CLIENT_ID: process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID,
  NEXT_PUBLIC_APPSYNC_URL: process.env.NEXT_PUBLIC_APPSYNC_URL,
  NEXT_PUBLIC_S3_BUCKET: process.env.NEXT_PUBLIC_S3_BUCKET
};

// Validate required environment variables
const requiredVars = [
  'NEXT_PUBLIC_AWS_REGION',
  'NEXT_PUBLIC_API_URL',
  'NEXT_PUBLIC_COGNITO_USER_POOL_ID',
  'NEXT_PUBLIC_COGNITO_CLIENT_ID'
];

const missingVars = requiredVars.filter(varName => !ENV_VARS[varName]);
if (missingVars.length > 0) {
  console.error('❌ Error: Missing required environment variables:');
  missingVars.forEach(varName => console.error(`   - ${varName}`));
  console.error('\nCreate a .env file with these variables or set them in your environment');
  process.exit(1);
}

const client = new AmplifyClient({ region: AWS_REGION });

async function deploy() {
  console.log('🚀 Deploying to AWS Amplify...\n');
  console.log(`Region: ${AWS_REGION}`);
  console.log(`App ID: ${AMPLIFY_APP_ID}\n`);

  try {
    // Update environment variables
    await client.send(new UpdateAppCommand({
      appId: AMPLIFY_APP_ID,
      environmentVariables: ENV_VARS
    }));
    console.log('✅ Updated environment variables');

    console.log('\n📋 Next steps:');
    console.log('\n1. Connect GitHub repository (if not already connected):');
    console.log(`   - Go to: https://console.aws.amazon.com/amplify/home?region=${AWS_REGION}#/${AMPLIFY_APP_ID}`);
    console.log('   - Click "Connect branch"');
    console.log('   - Select GitHub and authorize');
    console.log('   - Choose repository and branch');
    console.log('\n2. Or push to trigger deployment:');
    console.log('   git push origin main');
    console.log(`\n🌐 App URL: https://main.${AMPLIFY_APP_ID}.amplifyapp.com`);

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('\nTroubleshooting:');
    console.error('1. Verify AWS credentials are configured');
    console.error('2. Check AMPLIFY_APP_ID is correct');
    console.error('3. Ensure you have permissions to update Amplify apps');
    process.exit(1);
  }
}

deploy();
