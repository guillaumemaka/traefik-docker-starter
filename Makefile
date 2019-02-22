#######################################################
#								Work in Progress											#
#######################################################

IMAGE_NAME=traefik-proxy
SERVICE_NAME=$(IMAGE_NAME)
REPLICAS=1
NETWORK=web
SECRET=traefik-users
ENV_FILE=.env
DASHBOARD_FRONTEND_HOST=mgmt.guillaumemaka.com
COMPOSE_FILE=docker-compose.yml
BCRYPT_COST=10
PASSWD_FILE="$(PWD)/traefik/users"
USER=admin
PASSWORD=P@ssw0rd

###########################
#			Build image					$
###########################
build:
	@echo "Building image $(IMAGE_NAME)"
	docker build -t $(IMAGE_NAME) $(PWD)

###########################
#			Create a service    #
###########################
service: build generate-users
	@echo "Creating service $(SERVICE_NAME)"
	docker service create \
		--name $(SERVICE_NAME) \ 
		--env-file $(ENV_FILE) \
		--secret source$(SECRET),target=/etc/traefik/users  \
		--label traefik.enable="true" \
		--label traefik.frontend.rule=Host:"$(DASHBOARD_FRONTEND_HOST)" \
		--label traefik.port="8080" \
		--constraint 'node.role == manager' \
		--network $(NETWORK) \
		--publish published=80,target=80 \
		--publish published=443,target=443 \
		--publish target=8080 \
		--replicas $(REPLICAS) \
		$(IMAGE_NAME)

###########################
#			Swarm deploy				$
###########################
swarm-deploy: buid generate-users
	@echo "Deploying $(IMAGE_NAME)"
	docker stack deploy -c $(COMPOSE_FILE)

###########################
#	Generate Basic Auth			$
###########################
generate-users:
	@echo "Generating Basic Auth file"
	htpasswd -cdB -C $(BCRYPT_COST) $(PASSWD_FILE) $(USER) $(PASSWORD) && \
	@echo "Creating secret"
	docker secret create $(SECRET) $(PASSWD_FILE)
	echo "You can use user $(USER) with password $(PASSWORD)"
	
	
