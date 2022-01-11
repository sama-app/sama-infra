#!/bin/sh

PROMETHEUS_IMAGE_NAME=216862985054.dkr.ecr.eu-central-1.amazonaws.com/prometheus
PROMETHEUS_VERSION=latest

docker network create monitoring
eval "$(aws ecr get-login --region eu-central-1 --no-include-email)"
docker run -d \
    --name prometheus \
    -p 9090:9090 \
    --network monitoring \
    $PROMETHEUS_IMAGE_NAME:$PROMETHEUS_VERSION
