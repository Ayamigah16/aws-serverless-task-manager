const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const REGION = process.env.AWS_REGION || 'eu-west-1';
const USER_POOL_ID = process.env.USER_POOL_ID;
const ISSUER = `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}`;

const client = jwksClient({
  jwksUri: `${ISSUER}/.well-known/jwks.json`,
  cache: true,
  cacheMaxAge: 600000
});

function getKey(header, callback) {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      callback(err);
    } else {
      const signingKey = key.publicKey || key.rsaPublicKey;
      callback(null, signingKey);
    }
  });
}

function verifyToken(token) {
  return new Promise((resolve, reject) => {
    jwt.verify(token, getKey, { issuer: ISSUER }, (err, decoded) => {
      if (err) {
        reject(err);
      } else {
        resolve(decoded);
      }
    });
  });
}

function extractTokenFromEvent(event) {
  const authHeader = event.headers?.Authorization || event.headers?.authorization;
  
  if (!authHeader) {
    throw new Error('No authorization header');
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    throw new Error('Invalid authorization header format');
  }

  return parts[1];
}

function getUserGroups(decodedToken) {
  return decodedToken['cognito:groups'] || [];
}

function isAdmin(decodedToken) {
  const groups = getUserGroups(decodedToken);
  return groups.includes('Admins');
}

function isMember(decodedToken) {
  const groups = getUserGroups(decodedToken);
  return groups.includes('Members');
}

function getUserId(decodedToken) {
  return decodedToken.sub;
}

function getUserEmail(decodedToken) {
  return decodedToken.email;
}

async function validateRequest(event) {
  try {
    const token = extractTokenFromEvent(event);
    const decoded = await verifyToken(token);
    
    console.log('Token validated:', {
      userId: getUserId(decoded),
      email: getUserEmail(decoded),
      groups: getUserGroups(decoded)
    });

    return decoded;
  } catch (error) {
    console.error('Token validation failed:', error.message);
    throw error;
  }
}

module.exports = {
  verifyToken,
  extractTokenFromEvent,
  getUserGroups,
  isAdmin,
  isMember,
  getUserId,
  getUserEmail,
  validateRequest
};
