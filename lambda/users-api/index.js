const { CognitoIdentityProviderClient, ListUsersCommand, AdminListGroupsForUserCommand } = require('@aws-sdk/client-cognito-identity-provider');

const cognito = new CognitoIdentityProviderClient({ region: process.env.AWS_REGION || process.env.AWS_REGION_NAME || 'eu-west-1' });

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    const userPoolId = process.env.USER_POOL_ID;

    const listCommand = new ListUsersCommand({
      UserPoolId: userPoolId,
      Limit: 60
    });

    const response = await cognito.send(listCommand);

    const users = await Promise.all(response.Users.map(async (user) => {
      const username = user.Username;

      const groupsCommand = new AdminListGroupsForUserCommand({
        UserPoolId: userPoolId,
        Username: username
      });

      const groupsResponse = await cognito.send(groupsCommand);
      const groups = groupsResponse.Groups.map(g => g.GroupName);

      const attributes = {};
      user.Attributes.forEach(attr => {
        attributes[attr.Name] = attr.Value;
      });

      return {
        userId: attributes.sub,
        email: attributes.email,
        username: username,
        groups: groups,
        isAdmin: groups.includes('Admins'),
        status: user.UserStatus,
        enabled: user.Enabled
      };
    }));

    const activeUsers = users.filter(u => u.enabled && u.status !== 'FORCE_CHANGE_PASSWORD');

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ users: activeUsers, count: activeUsers.length })
    };

  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ message: error.message })
    };
  }
};
