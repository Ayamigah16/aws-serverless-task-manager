const { SNSClient, SubscribeCommand } = require('@aws-sdk/client-sns');

const snsClient = new SNSClient({});
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN;

exports.handler = async (event) => {
  console.log('Pre Sign-Up Trigger:', JSON.stringify(event, null, 2));

  const allowedDomains = process.env.ALLOWED_DOMAINS.split(',');
  const email = event.request.userAttributes.email;
  const domain = email.split('@')[1];

  console.log(`Validating email: ${email}, domain: ${domain}`);
  console.log(`Allowed domains: ${allowedDomains.join(', ')}`);

  if (!allowedDomains.includes(domain)) {
    console.error(`Blocked sign-up attempt - Invalid domain: ${domain} for email: ${email}`);
    throw new Error(`Invalid email domain. Only ${allowedDomains.join(', ')} are allowed.`);
  }

  console.log(`Valid domain: ${domain} - Allowing sign-up for: ${email}`);
  
  // Auto-subscribe user to SNS topic for notifications
  if (SNS_TOPIC_ARN) {
    try {
      await snsClient.send(new SubscribeCommand({
        TopicArn: SNS_TOPIC_ARN,
        Protocol: 'email',
        Endpoint: email,
        Attributes: {
          FilterPolicyScope: 'MessageAttributes',
          FilterPolicy: JSON.stringify({ email: [email] })
        }
      }));
      console.log(`SNS subscription created for ${email}`);
    } catch (error) {
      console.error('Failed to create SNS subscription:', error);
    }
  }
  
  event.response.autoConfirmUser = false;
  event.response.autoVerifyEmail = false;

  return event;
};
