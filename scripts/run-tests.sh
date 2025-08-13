#!/bin/bash

echo "Running comprehensive test suite..."

# Set test environment variables
export TEST_ENV=true
export DB_HOST=localhost
export KAFKA_BOOTSTRAP_SERVERS=localhost:9092
export REDIS_URL=localhost:6379

# Function to run tests for a service
run_service_tests() {
    local service=$1
    echo "Running tests for $service..."
    
    if [ -f "services/$service/pom.xml" ]; then
        cd "services/$service"
        mvn clean test
        if [ $? -ne 0 ]; then
            echo "Tests failed for $service"
            exit 1
        fi
        cd ../..
    elif [ -f "services/$service/package.json" ]; then
        cd "services/$service"
        npm test
        if [ $? -ne 0 ]; then
            echo "Tests failed for $service"
            exit 1
        fi
        cd ../..
    fi
}

# Start test infrastructure
echo "Starting test infrastructure..."
docker-compose -f docker-compose.test.yml up -d postgres-test redis-test kafka-test

# Wait for services to be ready
echo "Waiting for test infrastructure..."
sleep 30

# Run unit tests for each service
services=("patient-service" "appointment-service" "medical-records-service" "billing-service" "api-gateway")

for service in "${services[@]}"; do
    run_service_tests "$service"
done

# Run integration tests
echo "Running integration tests..."
cd integration-tests
npm test

# Run load tests
echo "Running load tests..."
if command -v k6 &> /dev/null; then
    k6 run load-tests/basic-load-test.js
fi

# Cleanup test infrastructure
echo "Cleaning up test infrastructure..."
docker-compose -f docker-compose.test.yml down -v

echo "All tests completed successfully!"