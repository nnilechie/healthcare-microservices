# Healthcare Microservices System

A comprehensive healthcare management system built with microservices architecture, featuring patient management, appointment scheduling, medical records, billing, and telemedicine capabilities.

## Architecture Overview

The system consists of the following microservices:
- **API Gateway**: Central entry point with authentication, rate limiting, and routing
- **Patient Service**: Patient registration, profile management, and medical history
- **Appointment Service**: Appointment scheduling, management, and notifications
- **Medical Records Service**: Electronic health records with HL7 FHIR compliance
- **Billing Service**: Medical billing, insurance claims, and payment processing
- **Telemedicine Service**: Video consultations and remote patient monitoring
- **Inventory Service**: Medical equipment and pharmaceutical inventory tracking
- **Notification Service**: Multi-channel notifications (email, SMS, push)
- **Analytics Service**: Business intelligence and reporting

## Technology Stack

- **Backend**: Java 17, Spring Boot 3.2, Node.js 18
- **Databases**: PostgreSQL 15, MongoDB 7, Redis 7
- **Message Broker**: Apache Kafka 3.5
- **Container Platform**: Docker, Kubernetes
- **Service Mesh**: Istio (optional)
- **Monitoring**: Prometheus, Grafana, ELK Stack
- **Security**: OAuth 2.0, JWT, TLS 1.3

## Prerequisites

- Docker 24.0+
- Docker Compose 2.21+
- Kubernetes 1.27+
- Helm 3.12+
- Java 17+
- Node.js 18+
- Maven 3.9+

## Quick Start

### Local Development

1. Install dependencies:
   ```bash
   make install-deps
   ```

2. Start the system:
   ```bash
   make deploy-local
   ```

3. Access the API:
   - API Gateway: http://localhost:8080
   - API Documentation: http://localhost:8080/api-docs
   - Health Check: http://localhost:8080/health

### Kubernetes Deployment

1. Build and push images:
   ```bash
   make build
   ```

2. Deploy to Kubernetes:
   ```bash
   make deploy-k8s
   ```

3. Setup monitoring:
   ```bash
   ./scripts/monitoring-setup.sh
   ```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `JWT_SECRET` | JWT signing secret | `your-secret-key` |
| `DB_HOST` | Database host | `localhost` |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka servers | `localhost:9092` |
| `REDIS_URL` | Redis connection | `localhost:6379` |

### Security Configuration

The system implements multiple security layers:
- OAuth 2.0 with JWT tokens
- Role-based access control (RBAC)
- API rate limiting
- HIPAA-compliant data encryption
- Network policies and service mesh security

## API Documentation

Complete API documentation is available at `/api-docs` when the system is running. Key endpoints include:

- `POST /auth/login` - User authentication
- `GET /api/v1/patients` - List patients
- `POST /api/v1/patients` - Create patient
- `GET /api/v1/appointments` - List appointments
- `POST /api/v1/appointments` - Schedule appointment

## Monitoring and Observability

The system includes comprehensive monitoring:
- **Metrics**: Prometheus with custom healthcare metrics
- **Logging**: Centralized logging with ELK Stack
- **Tracing**: Distributed tracing with Jaeger
- **Dashboards**: Grafana dashboards for system health

## Testing

Run the complete test suite:
```bash
make test
```

This includes:
- Unit tests for all services
- Integration tests
- API contract tests
- Load tests with K6

## Backup and Recovery

Automated backup system for:
- Database backups (PostgreSQL, MongoDB)
- Configuration backups
- Redis data snapshots

Run backup:
```bash
./scripts/backup.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Documentation: [docs/](docs/)
- Issues: [GitHub Issues](https://github.com/nnilechie/healthcare-microservices/issues)
- Email: nnilechie@myseneca.ca