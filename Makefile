.PHONY: help build test deploy clean

help: ## Display this help message
	@echo "Healthcare Microservices System"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all Docker images
	@echo "Building Docker images..."
	docker-compose build

test: ## Run all tests
	@echo "Running tests..."
	./scripts/run-tests.sh

deploy-local: ## Deploy to local environment using Docker Compose
	@echo "Deploying locally..."
	docker-compose up -d

deploy-k8s: ## Deploy to Kubernetes cluster
	@echo "Deploying to Kubernetes..."
	kubectl apply -f infrastructure/kubernetes/
	helm upgrade --install healthcare-system deployment/helm/healthcare-system/

clean: ## Clean up local environment
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f

setup-infra: ## Setup infrastructure using Terraform
	@echo "Setting up infrastructure..."
	cd deployment/terraform && terraform init && terraform apply

destroy-infra: ## Destroy infrastructure
	@echo "Destroying infrastructure..."
	cd deployment/terraform && terraform destroy

install-deps: ## Install development dependencies
	@echo "Installing dependencies..."
	./scripts/install-deps.sh