const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');

const s3 = new S3Client({});
const ddbClient = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(ddbClient);

const TABLE_NAME = process.env.TABLE_NAME;
const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf', 'text/plain', 'application/json'];
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

exports.handler = async (event) => {
  console.log('S3 Event:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
    const size = record.s3.object.size;

    console.log(`Processing file: ${key} (${size} bytes)`);

    try {
      // Get object metadata
      const getObjectResponse = await s3.send(new GetObjectCommand({
        Bucket: bucket,
        Key: key
      }));

      const contentType = getObjectResponse.ContentType;
      const metadata = getObjectResponse.Metadata || {};

      // Validate file type
      if (!ALLOWED_FILE_TYPES.includes(contentType)) {
        console.error(`Invalid file type: ${contentType}`);
        continue;
      }

      // Validate file size
      if (size > MAX_FILE_SIZE) {
        console.error(`File too large: ${size} bytes`);
        continue;
      }

      // Process images
      if (contentType.startsWith('image/')) {
        await processImage(bucket, key, getObjectResponse);
      }

      // Store attachment metadata in DynamoDB
      if (metadata.taskId && metadata.userId) {
        await storeAttachmentMetadata({
          taskId: metadata.taskId,
          userId: metadata.userId,
          fileName: key.split('/').pop(),
          fileSize: size,
          fileType: contentType,
          s3Key: key,
          bucket
        });
      }

      console.log(`Successfully processed: ${key}`);
    } catch (error) {
      console.error(`Error processing ${key}:`, error);
      throw error;
    }
  }
};

async function processImage(bucket, key, getObjectResponse) {
  try {
    // Read image data
    const imageBuffer = await streamToBuffer(getObjectResponse.Body);

    // Generate thumbnail
    const thumbnail = await sharp(imageBuffer)
      .resize(200, 200, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .jpeg({ quality: 80 })
      .toBuffer();

    // Upload thumbnail
    const thumbnailKey = key.replace('/uploads/', '/thumbnails/').replace(/\.[^.]+$/, '_thumb.jpg');
    
    await s3.send(new PutObjectCommand({
      Bucket: bucket,
      Key: thumbnailKey,
      Body: thumbnail,
      ContentType: 'image/jpeg',
      Metadata: getObjectResponse.Metadata
    }));

    console.log(`Generated thumbnail: ${thumbnailKey}`);

    // Get image metadata
    const metadata = await sharp(imageBuffer).metadata();
    console.log(`Image dimensions: ${metadata.width}x${metadata.height}`);

  } catch (error) {
    console.error('Error processing image:', error);
    // Don't throw - continue processing even if thumbnail generation fails
  }
}

async function storeAttachmentMetadata(data) {
  const attachmentId = uuidv4();
  const timestamp = new Date().toISOString();

  const attachment = {
    PK: `TASK#${data.taskId}`,
    SK: `ATTACHMENT#${attachmentId}`,
    EntityType: 'ATTACHMENT',
    attachmentId,
    taskId: data.taskId,
    fileName: data.fileName,
    fileSize: data.fileSize,
    fileType: data.fileType,
    s3Key: data.s3Key,
    bucket: data.bucket,
    uploadedBy: data.userId,
    uploadedAt: timestamp
  };

  await ddb.send(new PutCommand({
    TableName: TABLE_NAME,
    Item: attachment
  }));

  console.log(`Stored attachment metadata: ${attachmentId}`);
}

async function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('error', reject);
    stream.on('end', () => resolve(Buffer.concat(chunks)));
  });
}
