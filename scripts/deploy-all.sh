# scripts/deploy-all.sh
#!/bin/bash
kubectl apply -f manifests/secrets
kubectl apply -f manifests/databases
kubectl apply -f manifests/rabbitmq
kubectl apply -f manifests/inventory-app
kubectl apply -f manifests/billing-app
kubectl apply -f manifests/api-gateway-app
kubectl apply -f manifests/ingress
