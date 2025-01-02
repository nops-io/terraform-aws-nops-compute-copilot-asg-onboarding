import datetime

import boto3
import json
import os
import uuid


def lambda_handler(event, context):
    try:
        print('EVENT:[{}]'.format(event))
        lambda_client = boto3.client('lambda')
        test_event = json.dumps({
            "version": "0",
            "id": str(uuid.uuid4()),
            "detail-type": "Self Check Event",
            "source": "aws.events",
            "time": datetime.datetime.now().isoformat(),
            "region": os.environ["AWS_REGION"],
            "detail": {},
        })
        resp = lambda_client.invoke(
            FunctionName=f"nOps-ASG-{os.environ['AWS_REGION']}",
            InvocationType='RequestResponse',
            Payload=test_event,
        )
        payload = json.loads(resp['Payload'].read())

        status_code = payload.get('statusCode')
        body = json.loads(payload.get('body'))
        response_data = {"body": body, "status_code": status_code}
        return response_data
    except Exception as e:
        return {"result": str(e), "status_code": 500}
