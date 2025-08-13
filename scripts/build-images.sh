#!/bin/bash

echo "Building Docker images for all services..."

# Set registry and tag
REGISTRY=${REGISTRY:-"localhost:5000"}
TAG=${TAG:-"latest"}

# Services to build
services=("patient-service" "appointment-service" "medical-records-service" "billing-service" "telemedicine-service" "inventory-service" "notification-service" "analytics-service" "api-gateway")

# Build each service
for service in "${services[@]}"; do
    echo "Building $service..."
    
    if [ -f "services/$service/Dockerfile" ]; then
        docker build -t "$REGISTRY/healthcare/$service:$TAG" "services/$service"
        if [ $? -ne 0 ]; then
            echo "Failed to build $service"
            exit 1
        fi
    elif [ -f "gateway/$service/Dockerfile" ]; then
        docker build -t "$REGISTRY/healthcare/$service:$TAG" "gateway/$service"
        if [ $? -ne 0 ]; then
            echo "Failed to build $service"
            exit 1
        fi
    fi
    
    echo "$service built successfully"
done

# Push images if registry is not localhost
if [[ "$REGISTRY" != "localhost:5000" ]]; then
    echo "Pushing images to registry..."
    for service in "${services[@]}"; do
        docker push "$REGISTRY/healthcare/$service:$TAG"
    done
fi

echo "All images built successfully!"