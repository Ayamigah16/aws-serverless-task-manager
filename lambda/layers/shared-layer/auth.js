const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const region = process.env.AWS_REGION_NAME || 'eu-west-1';
const userPoolId = process.env.USER_POOL_ID;
const issuer = `https://cognito-idp.${region}.amazonaws.com/${userPoolId}`;

const client = jwksClient({
  jwksUri: `${issuer}/.well-known/jwks.json`,
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

async function verifyToken(token) {
  return new Promise((resolve, reject) => {
    jwt.verify(token, getKey, { issuer }, (err, decoded) => {
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
  return authHeader.replace('Bearer ', '');
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
    return decoded;
  } catch (error) {
    console.error('Token validation failed:', error.message);
    throw new Error(error.message);
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
