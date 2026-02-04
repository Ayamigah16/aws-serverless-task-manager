const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');

const client = new EventBridgeClient({});
const EVENT_BUS_NAME = process.env.EVENT_BUS_NAME || 'default';
const SOURCE = 'task-management.tasks';

async function publishEvent(detailType, detail) {
  const params = {
    Entries: [{
      Source: SOURCE,
      DetailType: detailType,
      Detail: JSON.stringify(detail),
      EventBusName: EVENT_BUS_NAME
    }]
  };

  console.log('Publishing event:', { detailType, detail });

  const result = await client.send(new PutEventsCommand(params));
  
  if (result.FailedEntryCount > 0) {
    console.error('Failed to publish event:', result.Entries);
    throw new Error('Failed to publish event');
  }

  console.log('Event published successfully');
  return result;
}

module.exports = {
  publishEvent
};
