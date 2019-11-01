#######################################################
#								Work in Progress											#
#######################################################

DOMAIN=docker.local
# IMAGE_TAG:=$(shell git describe --abbrev=0 --tags)
# IMAGE_NAME="traefik-proxy"
# SERVICE_NAME=$(IMAGE_NAME)
# REPLICAS=1
# NETWORK=web
SECRET=traefik-users
ENV_FILE=.env
DASHBOARD_FRONTEND_HOST=mgmt.$(DOMAIN)
COMPOSE_FILE=docker-compose.yml
BCRYPT_COST=10
PASSWD_FILE="$(PWD)/users"
USER=admin
PASSWORD=P@ssw0rd
DOCKER_REGISTRY_ADDR=127.0.0.1:5000
DOCKER_REGISTRY_CONTAINER_NAME=docker-registry
STACK_NAME=traefik

ifeq ($IMAGE_TAG,)
	IMAGE_TAG:="latest"
endif

###########################
#			Build image					#
###########################
build: generate-users
	@echo "Building image $(IMAGE_NAME):$(IMAGE_TAG)"
	docker build -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) $(PWD)
	docker image tag $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest

###########################
#			Create a service    #
###########################
# service: build generate-users
# 	@echo "Creating service $(SERVICE_NAME)"
# 	docker service create \
# 		--name $(SERVICE_NAME) \ 
# 		--env-file $(ENV_FILE) \
# 		--secret source$(SECRET),target=/etc/traefik/users  \
# 		--label traefik.enable="true" \
# 		--label traefik.frontend.rule=Host:"$(DASHBOARD_FRONTEND_HOST)" \
# 		--label traefik.port="8080" \
# 		--constraint 'node.role == manager' \
# 		--network $(NETWORK) \
# 		--publish published=80,target=80 \
# 		--publish published=443,target=443 \
# 		--publish target=8080 \
# 		--replicas $(REPLICAS) \
# 		$(IMAGE_NAME)

###########################
#			Swarm deploy				$
###########################
swarm-deploy: get-dependencies generate-users
	@echo "Deploying $(IMAGE_NAME)"
	docker stack deploy -c $(COMPOSE_FILE) $(STACK_NAME)

###########################
#	Generate Basic Auth			$
###########################
generate-users:
	@rm -f $(PASSWD_FILE)
	docker secret rm $(SECRET) > /dev/null
	@echo "Generating Basic Auth file"
	@htpasswd -cbB -C $(BCRYPT_COST) $(PASSWD_FILE) $(USER) $(PASSWORD)
	@echo "You can use user '$(USER)' with password $(PASSWORD)"
	@echo "Creating secret"
	@docker secret create $(SECRET) $(PASSWD_FILE)
	
get-dependencies:
	docker pull traefik:v2.0
	docker pull tecnativa/docker-socket-proxy:latest
	docker pull grafana/grafana:5.2
	docker pull prom/prometheus
	docker tag traefik:v2.0 $(DOCKER_REGISTRY_ADDR)/traefik:v2.0
	docker tag tecnativa/docker-socket-proxy:latest $(DOCKER_REGISTRY_ADDR)/tecnativa/docker-socket-proxy:latest
	docker tag grafana/grafana:5.2 $(DOCKER_REGISTRY_ADDR)/grafana/grafana:5.2
	docker tag prom/prometheus $(DOCKER_REGISTRY_ADDR)/prom/prometheus
	docker push $(DOCKER_REGISTRY_ADDR)/traefik:v2.0
	docker push $(DOCKER_REGISTRY_ADDR)/grafana/grafana:5.2
	docker push $(DOCKER_REGISTRY_ADDR)/prom/prometheus
	docker push $(DOCKER_REGISTRY_ADDR)/tecnativa/docker-socket-proxy:latest
	
