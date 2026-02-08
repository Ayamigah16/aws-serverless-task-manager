const { EventBridgeClient, PutEventsCommand } = require('@aws-sdk/client-eventbridge');

const client = new EventBridgeClient({});
const EVENT_BUS_NAME = process.env.EVENT_BUS_NAME;

async function publishEvent(detailType, detail) {
  const command = new PutEventsCommand({
    Entries: [{
      Source: 'task-manager',
      DetailType: detailType,
      Detail: JSON.stringify(detail),
      EventBusName: EVENT_BUS_NAME
    }]
  });
  
  await client.send(command);
}

module.exports = {
  publishEvent
};
