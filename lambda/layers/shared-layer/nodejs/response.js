function success(data, statusCode = 200) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': true
    },
    body: JSON.stringify(data)
  };
}

function error(message, statusCode = 500) {
  console.error('Error response:', { message, statusCode });
  
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': true
    },
    body: JSON.stringify({ error: message })
  };
}

function unauthorized(message = 'Unauthorized') {
  return error(message, 401);
}

function forbidden(message = 'Forbidden') {
  return error(message, 403);
}

function notFound(message = 'Not found') {
  return error(message, 404);
}

function badRequest(message = 'Bad request') {
  return error(message, 400);
}

function conflict(message = 'Conflict') {
  return error(message, 409);
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
