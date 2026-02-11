const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { v4: uuidv4 } = require('uuid');

const s3 = new S3Client({});
const BUCKET_NAME = process.env.BUCKET_NAME;
const URL_EXPIRATION = 3600; // 1 hour

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));

  const { field, arguments: args, identity } = event;
  const userId = identity.sub;

  try {
    switch (field) {
      case 'getPresignedUploadUrl':
        return await generateUploadUrl(args, userId);
      case 'getPresignedDownloadUrl':
        return await generateDownloadUrl(args, userId);
      default:
        throw new Error(`Unknown field: ${field}`);
    }
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};

async function generateUploadUrl(args, userId) {
  const { fileName, fileType, taskId } = args;

  // Validate file type
  const allowedTypes = [
    'image/jpeg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf',
    'text/plain', 'text/csv',
    'application/json',
    'application/zip',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  ];

  if (!allowedTypes.includes(fileType)) {
    throw new Error(`File type not allowed: ${fileType}`);
  }

  // Generate unique key
  const fileId = uuidv4();
  const extension = fileName.split('.').pop();
  const key = `uploads/${taskId}/${fileId}.${extension}`;

  // Create presigned URL for upload
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    ContentType: fileType,
    Metadata: {
      taskId,
      userId,
      originalFileName: fileName
    }
  });

  const url = await getSignedUrl(s3, command, { expiresIn: URL_EXPIRATION });

  return {
    url,
    expiresIn: URL_EXPIRATION,
    fields: JSON.stringify({
      key,
      bucket: BUCKET_NAME,
      'Content-Type': fileType
    })
  };
}

async function generateDownloadUrl(args, userId) {
  const { attachmentId } = args;

  // In a real implementation, you would:
  // 1. Query DynamoDB to get the S3 key for this attachment
  // 2. Verify the user has permission to access this file
  // For now, we'll use a simplified approach

  const key = `uploads/${attachmentId}`;

  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key
  });

  const url = await getSignedUrl(s3, command, { expiresIn: URL_EXPIRATION });

  return {
    url,
    expiresIn: URL_EXPIRATION,
    fields: null
  };
}
