init:
	@terraform -chdir=sama-service init -input=false

validate:
	terraform -chdir=sama-service fmt -check

dev-current-deployment:
	@terraform -chdir=sama-service show -json | \
	jq -r '.values.root_module.resources[] | select (.type == "aws_lb_listener") | .values.default_action[].forward[].target_group[] | select (.weight == 100) | .arn' | \
	grep -o -P '(?<=sama-service-).*(?=-tg-dev)'

dev-deploy-green:
	terraform -chdir=sama-service apply -auto-approve \
		-var 'enable_green_env=true' \
		-var 'enable_blue_env=false' \
		-var 'traffic_distribution=green'

dev-deploy-blue:
	terraform -chdir=sama-service apply -auto-approve \
		-var 'enable_green_env=false' \
		-var 'enable_blue_env=true' \
		-var 'traffic_distribution=blue'
