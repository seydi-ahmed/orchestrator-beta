# scripts/build-images.sh
#!/bin/bash
set -e

IMAGES=(inventory-app billing-app api-gateway-app rabbitmq postgres-db)
for IMAGE in "${IMAGES[@]}"; do
  echo "Building $IMAGE..."
  docker build -t monuser/$IMAGE:latest ./srcs/$IMAGE
done