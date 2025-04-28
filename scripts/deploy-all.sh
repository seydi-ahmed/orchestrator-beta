#!/bin/bash

#!/bin/bash

set -e

echo "[+] Deploying all Kubernetes manifests..."

# Installer nginx ingress controller d'abord
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

# Attendre quelques secondes que l'ingress controller soit prêt
echo "[+] Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# Maintenant déployer tes manifests
kubectl apply -f /vagrant/manifests/secrets/
kubectl apply -f /vagrant/manifests/databases/
kubectl apply -f /vagrant/manifests/billing-app/
kubectl apply -f /vagrant/manifests/inventory-app/
kubectl apply -f /vagrant/manifests/rabbitmq/
kubectl apply -f /vagrant/manifests/api-gateway-app/
kubectl apply -f /vagrant/manifests/ingress/

echo "[✓] All resources deployed to K3s cluster."
