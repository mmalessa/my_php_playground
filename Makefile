APP_NAME			= my_virtual_pizza_house
BASE_IMAGE			?= php:8.1.12-cli
####

DOCKER_COMPOSE		= docker-compose
DEV_DOCKERFILE		?= .docker/Dockerfile
APP_IMAGE			= $(APP_NAME)-app
CONTAINER_NAME		= $(APP_NAME)-app

PLATFORM			?= $(shell uname -s)
DEVELOPER_UID		?= $(shell id -u)
DOCKER_GATEWAY		?= $(shell if [ 'Linux' = "${PLATFORM}" ]; then ip addr show docker0 | awk '$$1 == "inet" {print $$2}' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; fi)

.DEFAULT_GOAL      = help

ARG := $(word 2, $(MAKECMDGOALS))
%:
	@:
help:
	@echo -e '\033[1m make [TARGET] \033[0m'
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

xdebug-setup: ## xdebug gateway setup
	@if [ "Linux" = "$(PLATFORM)" ]; then \
		sed "s/DOCKER_GATEWAY/$(DOCKER_GATEWAY)/g" .docker/php-ini-overrides.ini.dist > .docker/php-ini-overrides.ini; \
	fi

build: ## Build image
	@docker build -t $(APP_IMAGE)					\
	--build-arg BASE_IMAGE=$(BASE_IMAGE)			\
	--build-arg DEVELOPER_UID=$(DEVELOPER_UID)		\
	-f $(DEV_DOCKERFILE) .

up: xdebug-setup ## Start the project docker containers
	@cd ./.docker && \
	COMPOSE_PROJECT_NAME=$(APP_NAME) \
	APP_IMAGE=$(APP_IMAGE) \
	CONTAINER_NAME=$(CONTAINER_NAME) \
	$(DOCKER_COMPOSE) up -d

down: ## Remove the docker containers
	@cd ./.docker && \
	COMPOSE_PROJECT_NAME=$(APP_NAME) \
	APP_IMAGE=$(APP_IMAGE) \
	CONTAINER_NAME=$(CONTAINER_NAME) \
	$(DOCKER_COMPOSE) down

console: ## Enter into application container
	@docker exec -it -u developer $(CONTAINER_NAME) bash

tests: ## Run tests
	@./vendor/bin/phpunit --testsuite=all

tests-unit: ## Run tests
	@./vendor/bin/phpunit --testsuite=unit

tests-coverage: ## Run tests with coverage report
	@php -dxdebug.mode=coverage ./vendor/bin/phpunit --testsuite=coverage --coverage-text
