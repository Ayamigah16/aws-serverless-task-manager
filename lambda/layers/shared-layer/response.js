function createResponse(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
    },
    body: JSON.stringify(body)
  };
}

function success(data, statusCode = 200) {
  return createResponse(statusCode, data);
}

function error(message, statusCode = 500) {
  return createResponse(statusCode, { message });
}

function unauthorized(message = 'Unauthorized') {
  return createResponse(401, { message });
}

function forbidden(message = 'Forbidden') {
  return createResponse(403, { message });
}

function notFound(message = 'Not found') {
  return createResponse(404, { message });
}

function badRequest(message = 'Bad request') {
  return createResponse(400, { message });
}

function conflict(message = 'Conflict') {
  return createResponse(409, { message });
}

module.exports = {
  success,
  error,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  conflict
};
