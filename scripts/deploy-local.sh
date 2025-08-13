#!/bin/bash
echo "🚀 Starting Healthcare Microservices System locally..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "📦 Building and starting services..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 30

echo "🔍 Checking service health..."
echo "API Gateway: $(curl -s http://localhost:8080/health 2>/dev/null || echo 'Starting...')"

echo ""
echo "🎉 Healthcare System is starting up!"
echo "📋 Available endpoints:"
echo "   - API Gateway: http://localhost:8080/health"
echo "   - Patient Service: http://localhost:8081/actuator/health"
echo "   - Appointment Service: http://localhost:8082/actuator/health"
echo ""
echo "📊 To check status: make status"
echo "📋 To view logs: make logs"
echo "🛑 To stop: make stop"
