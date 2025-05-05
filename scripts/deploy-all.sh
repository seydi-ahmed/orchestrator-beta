#!/bin/bash

# ./scripts/deply-all.sh

#!/bin/bash
set -e

echo "[+] Deploying all Kubernetes manifests..."

# 1. Installer le Ingress Controller
kubectl apply -f /vagrant/manifests/ingress/ingress-nginx.yaml || { echo "[!] Failed to deploy ingress-nginx"; exit 1; }

# 2. Attendre que le Ingress Controller soit prêt
echo "[+] Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || { echo "[!] Ingress Controller timeout"; exit 1; }

# 3. Déployer les ressources dans l'ordre
kubectl apply -f /vagrant/manifests/secrets/ || { echo "[!] Failed to deploy secrets"; exit 1; }
kubectl apply -f /vagrant/manifests/databases/ || { echo "[!] Failed to deploy databases"; exit 1; }
kubectl apply -f /vagrant/manifests/rabbitmq/ || { echo "[!] Failed to deploy rabbitmq"; exit 1; }
kubectl apply -f /vagrant/manifests/billing-app/ || { echo "[!] Failed to deploy billing-app"; exit 1; }
kubectl apply -f /vagrant/manifests/inventory-app/ || { echo "[!] Failed to deploy inventory-app"; exit 1; }
kubectl apply -f /vagrant/manifests/api-gateway-app/ || { echo "[!] Failed to deploy api-gateway"; exit 1; }

kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission || true

# 4. Appliquer les règles Ingress (en dernier)
kubectl apply -f /vagrant/manifests/ingress/ingress.yaml || { echo "[!] Failed to deploy ingress rules"; exit 1; }

kubectl apply -f /vagrant/manifests/ingress/ingress-nginx.yaml

echo "[✓] All resources deployed to K3s cluster."