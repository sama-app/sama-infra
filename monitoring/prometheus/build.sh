#!/bin/sh
docker build -t prometheus .
docker tag prometheus:latest 216862985054.dkr.ecr.eu-central-1.amazonaws.com/prometheus:latest
docker push 216862985054.dkr.ecr.eu-central-1.amazonaws.com/prometheus:latest