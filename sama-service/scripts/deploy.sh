#!/bin/sh

curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
chmod +x ./awslogs-agent-setup.py
./awslogs-agent-setup.py -n -r eu-central-1 -c s3://cloudwatch-logs-sama/awslogs.conf

eval "$(aws ecr get-login --region eu-central-1 --no-include-email)"
docker volume create sama-service-logs
docker run -d \
      --name sama-service \
      -e X_JAVA_OPTS="-Dspring.datasource.host=sama-dev.cp9s2aovpufd.eu-central-1.rds.amazonaws.com -Dspring.datasource.port=5432 -Dspring.datasource.username=sama -Dspring.datasource.password=kvta26gvQTzgbJKL2XZP" \
      -p 3000:3000 \
      -v sama-service-logs:/var/log/sama/sama-service \
      216862985054.dkr.ecr.eu-central-1.amazonaws.com/sama-service:latest
