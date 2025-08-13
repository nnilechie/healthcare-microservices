#!/bin/bash

echo "Setting up monitoring stack..."

# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
echo "Installing Prometheus..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.retention=30d \
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=standard \
    --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi

# Install Grafana dashboards
echo "Installing Grafana dashboards..."
kubectl apply -f monitoring/grafana-dashboards/ -n monitoring

# Install ELK Stack for logging
echo "Installing ELK Stack..."
helm repo add elastic https://helm.elastic.co
helm upgrade --install elasticsearch elastic/elasticsearch \
    --namespace logging \
    --create-namespace \
    --set replicas=3 \
    --set volumeClaimTemplate.resources.requests.storage=30Gi

helm upgrade --install kibana elastic/kibana \
    --namespace logging \
    --set service.type=LoadBalancer

helm upgrade --install logstash elastic/logstash \
    --namespace logging

# Install Jaeger for distributed tracing
echo "Installing Jaeger..."
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.47.0/jaeger-operator.yaml -n observability

# Wait for operator to be ready
kubectl wait --for=condition=available deployment jaeger-operator -n observability --timeout=300s

# Deploy Jaeger instance
kubectl apply -f - <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: healthcare-jaeger
  namespace: observability
spec:
  strategy: production
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: http://elasticsearch-master.logging.svc.cluster.local:9200
EOF

echo "Monitoring stack setup completed!"
echo "Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
echo "Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
echo "Kibana: kubectl port-forward svc/kibana-kibana 5601:5601 -n logging"
