#!/usr/bin/env python

import os
import json
from datetime import datetime

def lambda_handler(event, context):
    ALP_VER = os.environ['ALP_VER']

    if event['headers']['user-agent'] == 'ELB-HealthChecker/2.0':
        data = 'OK'
    elif event['path'] == '/version':
        data = { 'version': ALP_VER }
    elif event['path'] == '/now':
        data = { 'now': str(datetime.now()) }

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json; charset=utf-8"
        },
        "isBase64Encoded": False,
        "body": json.dumps(data)
    }

    print(response)
    return response

if __name__ == '__main__':
    test_event = {
        "resource": "/",
        "path": "/now",
        "httpMethod": "GET",
        "requestContext": {
            "resourcePath": "/",
            "httpMethod": "GET",
            "path": "/now"
        },
        "headers": {
            "accept": "text/html",
            "accept-encoding": "gzip, deflate, br",
            "Host": "xxx.us-east-2.amazonaws.com",
            "user-agent": "Mozilla/5.0"
        },
        "multiValueHeaders": {
            "accept": [
                "text/html"
            ],
            "accept-encoding": [
                "gzip, deflate, br"
            ]
        },
        "queryStringParameters": {
            "postcode": 12345
        },
        "multiValueQueryStringParameters": None,
        "pathParameters": None,
        "stageVariables": None,
        "body": None,
        "isBase64Encoded": False
    }
  
    out = lambda_handler(test_event, {})
    print(out)
