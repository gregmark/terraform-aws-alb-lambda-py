#!/usr/bin/env python

import os
import sys
import requests

alb = os.environ['MY_ALB']
test_uri = 'http://{}/?alb'.format(alb)
uri = 'http://{}/{}'.format(alb, 'now')

# ensure alb is ok
try:
    response = requests.get(test_uri)
    response.raise_for_status()
except requests.exceptions.HTTPError as error:
    print(error)
    sys.exit(1)

print('OK')

invoke_payload = {
  "X-Amz-Invocation-Type": "DryRun",
  "X-Amz-Log-Type": "None",
  "X-Amz-Client-Context": ""
}

response = requests.get(uri, headers = invoke_payload)
print(response)

