import { Auth } from 'aws-amplify';

const awsConfig = {
  Auth: {
    region: process.env.REACT_APP_REGION || 'eu-west-1',
    userPoolId: process.env.REACT_APP_USER_POOL_ID,
    userPoolWebClientId: process.env.REACT_APP_USER_POOL_CLIENT_ID,
    oauth: {
      domain: process.env.REACT_APP_COGNITO_DOMAIN,
      scope: ['email', 'openid', 'profile'],
      redirectSignIn: process.env.REACT_APP_REDIRECT_SIGN_IN || 'http://localhost:3000',
      redirectSignOut: process.env.REACT_APP_REDIRECT_SIGN_OUT || 'http://localhost:3000',
      responseType: 'code'
    }
  },
  API: {
    endpoints: [
      {
        name: 'TaskAPI',
        endpoint: process.env.REACT_APP_API_URL,
        region: process.env.REACT_APP_REGION || 'eu-west-1',
        custom_header: async () => {
          try {
            const session = await Auth.currentSession();
            return {
              Authorization: `Bearer ${session.getIdToken().getJwtToken()}`
            };
          } catch (error) {
            console.error('Error getting auth token:', error);
            return {};
          }
        }
      }
    ]
  }
};

export default awsConfig;
