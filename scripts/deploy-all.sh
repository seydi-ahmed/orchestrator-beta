# ./scripts/deploy-all.sh

#!/bin/bash

set -e

echo "[+] Deploying all Kubernetes manifests..."

# 1. Deploy ingress controller first
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

echo "[~] Waiting for ingress controller pod to be ready..."

kubectl wait --namespace ingress-nginx \
  --for=condition=Ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

# 2. Deploy all secrets
kubectl apply -f /vagrant/manifests/secrets/

# 3. Deploy databases
kubectl apply -f /vagrant/manifests/databases/

# 4. Deploy billing app
kubectl apply -f /vagrant/manifests/billing-app/

# 5. Deploy inventory app
kubectl apply -f /vagrant/manifests/inventory-app/

# 6. Deploy rabbitmq
kubectl apply -f /vagrant/manifests/rabbitmq/

# 7. Deploy api gateway
kubectl apply -f /vagrant/manifests/api-gateway-app/

# 8. Deploy ingress
kubectl apply -f /vagrant/manifests/ingress/ingress.yaml

echo "[✓] All resources deployed to K3s cluster."
