#!/bin/bash

# ./scripts/deply-all.sh

set -e

echo "[+] Deploying all Kubernetes manifests..."

# 1. Déployer les secrets
kubectl apply -f /vagrant/manifests/secrets/ || { echo "[!] Failed to deploy secrets"; exit 1; }

echo "[*] Waiting for secrets to be fully available..."
SECRETS=("billing-db-secret" "inventory-db-secret" "rabbitmq-secret")
for secret in "${SECRETS[@]}"; do
  while true; do
    if kubectl get secret "$secret" > /dev/null 2>&1; then
      echo "[+] Secret $secret is available"
      break
    fi
    echo "[.] Waiting for secret $secret to be available..."
    sleep 2
  done
done

# 2. Déployer le ConfigMap
kubectl apply -f /vagrant/manifests/configmaps/app-config.yaml || { echo "[!] Failed to deploy ConfigMap"; exit 1; }
echo "[+] ConfigMap app-config deployed"

# 3. Déployer les bases de données, rabbitmq, et les apps
kubectl apply -f /vagrant/manifests/databases/ || { echo "[!] Failed to deploy databases"; exit 1; }
kubectl apply -f /vagrant/manifests/rabbitmq/ || { echo "[!] Failed to deploy rabbitmq"; exit 1; }
kubectl apply -f /vagrant/manifests/billing-app/ || { echo "[!] Failed to deploy billing-app"; exit 1; }
kubectl apply -f /vagrant/manifests/inventory-app/ || { echo "[!] Failed to deploy inventory-app"; exit 1; }
kubectl apply -f /vagrant/manifests/api-gateway-app/ || { echo "[!] Failed to deploy api-gateway"; exit 1; }

# 4. Déployer les règles Ingress
kubectl apply -f /vagrant/manifests/ingress/ingress.yaml || { echo "[!] Failed to deploy ingress rules"; exit 1; }

echo "[✓] All resources deployed to K3s cluster."
