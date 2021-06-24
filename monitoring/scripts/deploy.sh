#!/bin/sh

PROMETHEUS_IMAGE_NAME=216862985054.dkr.ecr.eu-central-1.amazonaws.com/prometheus
PROMETHEUS_VERSION=latest

GRAFANA_IMAGE_NAME=216862985054.dkr.ecr.eu-central-1.amazonaws.com/grafana
GRAFANA_VERSION=latest

docker network create monitoring
eval "$(aws ecr get-login --region eu-central-1 --no-include-email)"
docker run -d \
    --name prometheus \
    -p 9090:9090 \
    --network monitoring \
    $PROMETHEUS_IMAGE_NAME:$PROMETHEUS_VERSION


docker volume create grafana-storage
docker run -d \
    --name grafana \
    -v grafana-storage:/var/lib/grafana \
    -p 3000:3000 \
    --network monitoring \
    $GRAFANA_IMAGE_NAME:$GRAFANA_VERSION
