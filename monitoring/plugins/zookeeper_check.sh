#!/bin/bash

output=$(echo ruok | nc localhost 2181)

if [ $output != 'imok' ]; then
  echo "status CRITICAL zookeeper not healthy"
  exit 1
fi

echo "status OK zookeeper is healthy"
