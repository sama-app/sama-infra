init:
	terraform -chdir=sama-service init -input=false

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
