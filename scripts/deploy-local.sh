#!/bin/bash

echo "Deploying Healthcare System locally..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker first."
    exit 1
fi

# Create necessary directories
mkdir -p logs
mkdir -p data/postgres
mkdir -p data/mongodb
mkdir -p data/redis

# Set environment variables
export COMPOSE_PROJECT_NAME=healthcare
export LOG_LEVEL=INFO

# Pull latest images
echo "Pulling latest images..."
docker-compose pull

# Build custom images
echo "Building custom images..."
docker-compose build

# Start the infrastructure services first
echo "Starting infrastructure services..."
docker-compose up -d zookeeper kafka redis postgres-patient postgres-appointment postgres-billing mongodb

# Wait for infrastructure to be ready
echo "Waiting for infrastructure services..."
sleep 60

# Start the application services
echo "Starting application services..."
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
timeout=300
counter=0

while [ $counter -lt $timeout ]; do
    if curl -f http://localhost:8080/health >/dev/null 2>&1; then
        echo "API Gateway is healthy!"
        break
    fi
    echo "Waiting for API Gateway... ($counter/$timeout)"
    sleep 5
    counter=$((counter + 5))
done

if [ $counter -ge $timeout ]; then
    echo "Timeout waiting for services to be healthy"
    docker-compose logs
    exit 1
fi

echo "Healthcare System deployed successfully!"
echo "API Gateway: http://localhost:8080"
echo "API Documentation: http://localhost:8080/api-docs"
echo "Health Check: http://localhost:8080/health"