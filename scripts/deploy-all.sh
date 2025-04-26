# ./scripts/deploy-all.sh
#!/bin/bash

set -e

echo "[+] Deploying all Kubernetes manifests..."

kubectl apply -f /vagrant/manifests/secrets/
kubectl apply -f /vagrant/manifests/secrets/
kubectl apply -f /vagrant/manifests/secrets/

kubectl apply -f /vagrant/manifests/databases/
kubectl apply -f /vagrant/manifests/databases/

kubectl apply -f /vagrant/manifests/billing-app/
kubectl apply -f /vagrant/manifests/billing-app/

kubectl apply -f /vagrant/manifests/inventory-app/
kubectl apply -f /vagrant/manifests/inventory-app/

kubectl apply -f /vagrant/manifests/rabbitmq/
kubectl apply -f /vagrant/manifests/rabbitmq/

kubectl apply -f /vagrant/manifests/api-gateway-app/
kubectl apply -f /vagrant/manifests/api-gateway-app/

kubectl apply -f /vagrant/manifests/ingress/ingress.yaml

# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/kind/deploy.yaml

echo "[✓] All resources deployed to K3s cluster."
