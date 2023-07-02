import { Context, APIGatewayProxyResult, APIGatewayEvent } from 'aws-lambda';

export const handler = async (
  event: APIGatewayEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log(`Events: ${JSON.stringify(event)}`);
  console.log(`Context: ${JSON.stringify(context)}`);
  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Amazing!'
    })
  };
};
