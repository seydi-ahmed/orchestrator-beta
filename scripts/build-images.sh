# scripts/build-images.sh
#!/bin/bash

set -e

echo "[+] Building Docker images..."

# App components
docker build -t mouhameddiouf01/inventory-app:latest ./srcs/inventory-app
docker build -t mouhameddiouf01/billing-app:latest ./srcs/billing-app
docker build -t mouhameddiouf01/api-gateway:latest ./srcs/api-gateway-app

# mako si yokeu
docker build -t mouhameddiouf01/api-gateway-app:latest ./srcs/api-gateway-app

# Services
docker build -t mouhameddiouf01/postgres-db:latest ./srcs/postgres-db
docker build -t mouhameddiouf01/rabbitmq:latest ./srcs/rabbitmq

echo "[✓] Docker images built successfully."
