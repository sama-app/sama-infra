#!/bin/sh

environment=$(aws ec2 --region eu-central-1 describe-tags --filters "Name=resource-id,Values=$(ec2metadata --instance-id)" | \
               jq -r '.Tags[] | select(.Key=="Environment")'.Value)

export ENV=$environment
