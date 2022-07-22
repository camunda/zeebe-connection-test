#!/usr/bin/env bash

docker run --rm -p 26500:26500 -e ZEEBE_BROKER_NETWORK_HOST=0.0.0.0 camunda/zeebe:8.0.4