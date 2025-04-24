# scripts/push-images.sh
#!/bin/bash

set -e

echo "[+] Pushing Docker images to Docker Hub..."

docker push mouhameddiouf01/inventory-app:latest
docker push mouhameddiouf01/billing-app:latest
docker push mouhameddiouf01/api-gateway:latest
docker push mouhameddiouf01/postgres-db:latest
docker push mouhameddiouf01/rabbitmq:latest

# mako fi yokeu
docker push mouhameddiouf01/api-gateway-app:latest

echo "[✓] All images pushed to Docker Hub."
