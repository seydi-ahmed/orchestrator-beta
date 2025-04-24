# scripts/deploy-all.sh
#!/bin/bash

set -e

echo "[+] Deploying all Kubernetes manifests..."

kubectl apply -f manifests/secrets
kubectl apply -f manifests/databases
kubectl apply -f manifests/billing-app
kubectl apply -f manifests/inventory-app
kubectl apply -f manifests/rabbitmq
kubectl apply -f manifests/api-gateway-app
kubectl apply -f manifests/ingress

echo "[✓] All resources deployed to K3s cluster."
