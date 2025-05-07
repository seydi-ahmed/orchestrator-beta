#!/bin/bash

# ./scripts/deply-all.sh

set -e

echo "[+] Deploying all Kubernetes manifests..."

# 1. Déployer les ressources dans l'ordre
kubectl apply -f /vagrant/manifests/secrets/ || { echo "[!] Failed to deploy secrets"; exit 1; }

echo "[*] Waiting for secrets to be fully available..."

# Vérifier que tous les secrets sont créés
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

kubectl apply -f /vagrant/manifests/databases/ || { echo "[!] Failed to deploy databases"; exit 1; }
kubectl apply -f /vagrant/manifests/rabbitmq/ || { echo "[!] Failed to deploy rabbitmq"; exit 1; }
kubectl apply -f /vagrant/manifests/billing-app/ || { echo "[!] Failed to deploy billing-app"; exit 1; }
kubectl apply -f /vagrant/manifests/inventory-app/ || { echo "[!] Failed to deploy inventory-app"; exit 1; }
kubectl apply -f /vagrant/manifests/api-gateway-app/ || { echo "[!] Failed to deploy api-gateway"; exit 1; }

# 2. Appliquer les règles Ingress (en dernier)
kubectl apply -f /vagrant/manifests/ingress/ingress.yaml || { echo "[!] Failed to deploy ingress rules"; exit 1; }

echo "[✓] All resources deployed to K3s cluster."
