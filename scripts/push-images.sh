# scripts/push-images.sh
#!/bin/bash
set -e

IMAGES=(inventory-app billing-app api-gateway-app rabbitmq postgres-db)
for IMAGE in "${IMAGES[@]}"; do
  echo "Pushing $IMAGE..."
  docker push monuser/$IMAGE:latest
done