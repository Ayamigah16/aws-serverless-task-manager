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
  
  event.response.autoConfirmUser = true;
  event.response.autoVerifyEmail = true;

  return event;
};
