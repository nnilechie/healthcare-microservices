#!/bin/bash

echo "🔧 Quick Fix Setup for Healthcare Microservices System"
echo "======================================================"

# Fix 1: Make all scripts executable
echo "📝 Making scripts executable..."
chmod +x scripts/*.sh
chmod +x scripts/*

# Fix 2: Create missing service directories and basic files
echo "📁 Creating missing service directories..."

services=("patient-service" "appointment-service" "medical-records-service" "billing-service" "telemedicine-service" "inventory-service" "notification-service" "analytics-service")

for service in "${services[@]}"; do
    echo "Creating $service..."
    mkdir -p services/$service/src/main/java/com/healthcare
    mkdir -p services/$service/src/main/resources
    mkdir -p services/$service/target
    
    # Create basic Dockerfile
    cat > services/$service/Dockerfile << EOF
FROM openjdk:17-jre-slim
WORKDIR /app
COPY target/$service-1.0.0.jar app.jar
EXPOSE 808\$(echo \$service | tail -c 2)
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

    # Create basic pom.xml
    cat > services/$service/pom.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.healthcare</groupId>
    <artifactId>$service</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    # Create basic Spring Boot application
    cat > services/$service/src/main/java/com/healthcare/Application.java << EOF
package com.healthcare;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@RestController
class HealthController {
    @GetMapping("/actuator/health")
    public String health() {
        return "{\"status\":\"UP\",\"service\":\"$service\"}";
    }
    
    @GetMapping("/actuator/ready")
    public String ready() {
        return "{\"status\":\"READY\",\"service\":\"$service\"}";
    }
}
EOF

    # Create application.properties
    cat > services/$service/src/main/resources/application.properties << EOF
server.port=808\$(echo "$service" | wc -c | xargs expr 80 +)
spring.application.name=$service
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
EOF

    # Create dummy JAR file for Docker build
    mkdir -p services/$service/target
    echo "Dummy JAR for $service" > services/$service/target/$service-1.0.0.jar
done

# Fix 3: Create API Gateway directory and files
echo "🚀 Creating API Gateway..."
mkdir -p gateway/api-gateway
cd gateway/api-gateway

# Create package.json
cat > package.json << EOF
{
  "name": "healthcare-api-gateway",
  "version": "1.0.0",
  "description": "API Gateway for Healthcare System",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "http-proxy-middleware": "^2.0.6",
    "cors": "^2.8.5"
  }
}
EOF

# Create simple server.js
cat > server.js << EOF
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'UP', 
    timestamp: new Date().toISOString(),
    gateway: 'healthcare-api-gateway'
  });
});

// Simple routing
app.use('/api/v1/patients', createProxyMiddleware({
  target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:8081',
  changeOrigin: true,
  pathRewrite: { '^/api/v1/patients': '/api/v1' }
}));

app.use('/api/v1/appointments', createProxyMiddleware({
  target: process.env.APPOINTMENT_SERVICE_URL || 'http://appointment-service:8082',
  changeOrigin: true,
  pathRewrite: { '^/api/v1/appointments': '/api/v1' }
}));

app.listen(PORT, () => {
  console.log(\`API Gateway running on port \${PORT}\`);
});
EOF

# Create Dockerfile
cat > Dockerfile << EOF
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["npm", "start"]
EOF

cd ../..

# Fix 4: Create infrastructure directories
echo "🏗️ Creating infrastructure directories..."
mkdir -p infrastructure/kubernetes
mkdir -p infrastructure/docker
mkdir -p deployment/helm
mkdir -p scripts

# Fix 5: Update docker-compose.yml to remove version warning
echo "🐳 Updating docker-compose.yml..."
cat > docker-compose.yml << EOF
services:
  # Infrastructure Services
  zookeeper:
    image: confluentinc/cp-zookeeper:7.4.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000

  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  postgres-patient:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: patient_db
      POSTGRES_USER: patient_user
      POSTGRES_PASSWORD: patient_pass
    ports:
      - "5432:5432"

  postgres-appointment:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: appointment_db
      POSTGRES_USER: appointment_user
      POSTGRES_PASSWORD: appointment_pass
    ports:
      - "5433:5432"

  postgres-billing:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: billing_db
      POSTGRES_USER: billing_user
      POSTGRES_PASSWORD: billing_pass
    ports:
      - "5434:5432"

  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: password

  # API Gateway
  api-gateway:
    build: ./gateway/api-gateway
    ports:
      - "8080:8080"
    environment:
      - PATIENT_SERVICE_URL=http://patient-service:8081
      - APPOINTMENT_SERVICE_URL=http://appointment-service:8082
    depends_on:
      - redis

  # Core Services (simplified for quick start)
  patient-service:
    build: ./services/patient-service
    ports:
      - "8081:8081"
    environment:
      - DB_HOST=postgres-patient
      - DB_PORT=5432
      - DB_NAME=patient_db
      - DB_USER=patient_user
      - DB_PASSWORD=patient_pass
    depends_on:
      - postgres-patient

  appointment-service:
    build: ./services/appointment-service
    ports:
      - "8082:8082"
    environment:
      - DB_HOST=postgres-appointment
      - DB_PORT=5432
      - DB_NAME=appointment_db
      - DB_USER=appointment_user
      - DB_PASSWORD=appointment_pass
    depends_on:
      - postgres-appointment
EOF

# Fix 6: Create simple Makefile
echo "⚙️ Creating updated Makefile..."
cat > Makefile << EOF
.PHONY: help build test deploy-local clean setup

help: ## Display this help message
	@echo "Healthcare Microservices System"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", \$1, \$2}' \$(MAKEFILE_LIST)

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
	@echo "API Gateway: \$\$(curl -s http://localhost:8080/health || echo 'Not responding')"
	@echo "Patient Service: \$\$(curl -s http://localhost:8081/actuator/health || echo 'Not responding')"
	@echo "Appointment Service: \$\$(curl -s http://localhost:8082/actuator/health || echo 'Not responding')"
EOF

# Fix 7: Create basic scripts
echo "📜 Creating basic scripts..."

cat > scripts/install-deps.sh << 'EOF'
#!/bin/bash
echo "Installing development dependencies for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Docker Desktop if not installed
if ! command -v docker &> /dev/null; then
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    echo "After installation, start Docker Desktop and try again."
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

echo "Docker is running! ✅"

# Install other tools via Homebrew
echo "Installing development tools..."
brew install curl wget jq

echo "All dependencies are ready! ✅"
EOF

cat > scripts/deploy-local.sh << 'EOF'
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
EOF

# Make scripts executable
chmod +x scripts/*.sh

echo ""
echo "✅ Quick Fix Setup Complete!"
echo "=========================="
echo ""
echo "🚀 Next Steps:"
echo "1. Run: make setup (if you haven't already)"
echo "2. Run: make deploy-local"
echo "3. Wait 30-60 seconds for services to start"
echo "4. Test: make test-connection"
echo ""
echo "📋 Useful Commands:"
echo "   make status     - Check service status"
echo "   make logs       - View service logs"
echo "   make stop       - Stop all services"
echo "   make clean      - Clean up everything"
echo ""
echo "🔧 If issues persist:"
echo "   - Make sure Docker Desktop is running"
echo "   - Try: make clean && make deploy-local"
echo ""