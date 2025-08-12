#!/bin/bash

echo "Deploying Healthcare System to Kubernetes..."

# Set variables
NAMESPACE=${NAMESPACE:-"healthcare-system"}
REGISTRY=${REGISTRY:-"your-registry.com"}
TAG=${TAG:-"latest"}

# Check if kubectl is configured
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "kubectl is not configured or cluster is not accessible"
    exit 1
fi

# Create namespace
echo "Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMaps and Secrets
echo "Applying configurations..."
kubectl apply -f infrastructure/kubernetes/configmap.yaml -n $NAMESPACE
kubectl apply -f infrastructure/kubernetes/secrets.yaml -n $NAMESPACE

# Deploy infrastructure components
echo "Deploying infrastructure..."
kubectl apply -f infrastructure/kubernetes/postgres-deployment.yaml -n $NAMESPACE
kubectl apply -f infrastructure/kubernetes/pvc.yaml -n $NAMESPACE

# Wait for infrastructure to be ready
echo "Waiting for infrastructure..."
kubectl wait --for=condition=ready pod -l app=postgres-patient -n $NAMESPACE --timeout=300s

# Deploy application services
echo "Deploying application services..."
kubectl apply -f infrastructure/kubernetes/patient-service-deployment.yaml -n $NAMESPACE
kubectl apply -f infrastructure/kubernetes/patient-service-service.yaml -n $NAMESPACE
kubectl apply -f infrastructure/kubernetes/api-gateway-deployment.yaml -n $NAMESPACE
kubectl apply -f infrastructure/kubernetes/api-gateway-service.yaml -n $NAMESPACE

# Deploy ingress
echo "Deploying ingress..."
kubectl apply -f infrastructure/kubernetes/ingress.yaml -n $NAMESPACE

# Deploy monitoring
echo "Deploying monitoring..."
kubectl apply -f infrastructure/kubernetes/monitoring.yaml -n $NAMESPACE

# Deploy autoscaling
echo "Deploying autoscaling..."
kubectl apply -f infrastructure/kubernetes/hpa.yaml -n $NAMESPACE

# Deploy network policies
echo "Deploying network policies..."
kubectl apply -f infrastructure/kubernetes/network-policy.yaml -n $NAMESPACE

# Wait for deployments to be ready
echo "Waiting for deployments..."
kubectl wait --for=condition=available deployment --all -n $NAMESPACE --timeout=600s

# Get service status
echo "Deployment completed! Service status:"
kubectl get pods,services,ingress -n $NAMESPACE

# Get external IP
external_ip=$(kubectl get service api-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$external_ip" ]; then
    echo "API Gateway accessible at: http://$external_ip:8080"
else
    echo "API Gateway service is being provisioned. Check 'kubectl get svc -n $NAMESPACE' for updates."
fi
