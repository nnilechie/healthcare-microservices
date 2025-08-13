.PHONY: help build test deploy-local clean setup

help: ## Display this help message
	@echo "Healthcare Microservices System"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $1, $2}' $(MAKEFILE_LIST)

setup: ## Setup the project (run this first)
	@echo "Setting up Healthcare Microservices System..."
	chmod +x scripts/*.sh
	chmod +x quick-fix-setup.sh
	./quick-fix-setup.sh

build: ## Build all Docker images
	@echo "Building Docker images..."
	docker-compose build

deploy-local: ## Deploy to local environment using Docker Compose
	@echo "Deploying locally..."
	docker-compose up -d

stop: ## Stop local deployment
	@echo "Stopping services..."
	docker-compose down

clean: ## Clean up local environment
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f

logs: ## Show logs from all services
	docker-compose logs -f

status: ## Show status of all services
	docker-compose ps

test-connection: ## Test if services are responding
	@echo "Testing service connections..."
	@echo "API Gateway: $$(curl -s http://localhost:8080/health || echo 'Not responding')"
	@echo "Patient Service: $$(curl -s http://localhost:8081/actuator/health || echo 'Not responding')"
	@echo "Appointment Service: $$(curl -s http://localhost:8082/actuator/health || echo 'Not responding')"
