#!/bin/bash

echo "Starting backup process..."

BACKUP_DIR="/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup databases
echo "Backing up databases..."

# PostgreSQL backups
for db in patient_db appointment_db billing_db; do
    kubectl exec -n healthcare-system deployment/postgres-patient -- pg_dump -U postgres $db > $BACKUP_DIR/$db.sql
done

# MongoDB backup
kubectl exec -n healthcare-system deployment/mongodb -- mongodump --out /tmp/mongodb_backup
kubectl cp healthcare-system/deployment/mongodb:/tmp/mongodb_backup $BACKUP_DIR/mongodb_backup

# Backup Kubernetes configurations
echo "Backing up Kubernetes configurations..."
kubectl get all -n healthcare-system -o yaml > $BACKUP_DIR/k8s_resources.yaml
kubectl get secrets -n healthcare-system -o yaml > $BACKUP_DIR/k8s_secrets.yaml
kubectl get configmaps -n healthcare-system -o yaml > $BACKUP_DIR/k8s_configmaps.yaml

# Backup Redis data
echo "Backing up Redis data..."
kubectl exec -n healthcare-system deployment/redis -- redis-cli BGSAVE
kubectl cp healthcare-system/deployment/redis:/data/dump.rdb $BACKUP_DIR/redis_dump.rdb

# Compress backup
echo "Compressing backup..."
tar -czf "${BACKUP_DIR}.tar.gz" -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)
rm -rf $BACKUP_DIR

echo "Backup completed: ${BACKUP_DIR}.tar.gz"

# Upload to cloud storage (example for AWS S3)
if [ -n "$AWS_S3_BUCKET" ]; then
    aws s3 cp "${BACKUP_DIR}.tar.gz" "s3://$AWS_S3_BUCKET/backups/"
    echo "Backup uploaded to S3"
fi
