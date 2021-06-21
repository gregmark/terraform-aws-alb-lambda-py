#!/bin/bash

cd $(git rev-parse --show-toplevel)/level0

alb=$(terraform output -raw lambda_dns 2>/dev/null)

uri="http://${alb:?terraform output not found}"

opt="$1"

if [ "$opt" == "-h" ]; then
  echo "curl $uri"
else
  curl ${uri}/${1}
fi
