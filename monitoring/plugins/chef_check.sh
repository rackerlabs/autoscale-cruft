#!/bin/bash

if [ ! -x "$(command -v chef-client)" ]; then
  echo "status CRITICAL cant find chef-client"
  exit 1
fi

echo "status chef_version checked successfully"
echo "metric chef_version double $(chef-client -v | awk '{print $2}')"
