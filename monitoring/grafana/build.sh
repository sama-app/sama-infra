#!/bin/sh
docker build -t grafana .
docker tag grafana:latest 216862985054.dkr.ecr.eu-central-1.amazonaws.com/grafana:latest
docker push 216862985054.dkr.ecr.eu-central-1.amazonaws.com/grafana:latest