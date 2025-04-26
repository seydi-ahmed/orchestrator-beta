# ./scripts/deploy-all.sh

#!/bin/bash
set -e

echo "[+] Verifying cluster access..."
kubectl cluster-info || { echo "[!] Cluster inaccessible"; exit 1; }

echo "[+] Checking Helm installation..."
helm version || { echo "[!] Helm not installed"; exit 1; }

echo "[+] Deploying all Kubernetes manifests..."

# 1. Installer NGINX Ingress avec Helm (plus fiable)
echo "[+] Adding Helm repos..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "[+] Installing NGINX Ingress..."
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

echo "[~] Waiting for ingress controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=Available deployment \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# 2. Appliquer les manifests dans le bon ordre
DEPLOY_ORDER=(
  "secrets"
  "databases" 
  "rabbitmq"
  "billing-app"
  "inventory-app"
  "api-gateway-app"
  "ingress"
)

for component in "${DEPLOY_ORDER[@]}"; do
  echo "[+] Deploying $component..."
  kubectl apply -f /shared/manifests/$component/
done

echo "[✓] All resources deployed to K3s cluster."