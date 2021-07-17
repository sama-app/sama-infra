#!/bin/sh

curl -s https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add - && \
echo "license_key: eu01xx251df55d793dd5a5d3416900aded02NRAL" | sudo tee -a /etc/newrelic-infra.yml && \
printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt focal main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list && \
sudo apt-get update && \
sudo apt-get install newrelic-infra -y

sudo mv newrelic-logging.yml /etc/newrelic-infra/logging.d/logging.yml