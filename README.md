# orchestrator

## Rappel

### Projet 1 - Microservices:
1) développer trois applications : api-gateway-app, inventory-app, billing-app.
2) utiliser deux bases PostgreSQL : billing-db, inventory-db.
3) utiliser RabbitMQ comme système de message pour billing-app.

### Projet 2 - Dockerisation:
1) docker-compose.yml qui orchestre les services.
2) chaque microservice et composant a son propre Dockerfile.
3) relier les apps aux services dont elles dépendent (depends_on + healthcheck).
4) utiliser des volumes pour la persistance (DB & RabbitMQ).

## Projet 3(actuel) - Kubernetes (K3s + Vagrant):
1) tout migrer vers K8s (K3s sur 2 VMs : master + agent).
2) docker-pusher les images sur Docker Hub.
3) écrire des manifests (YAMLs) pour:
- Deployments (ou StatefulSet pour DB et billing-app)
- Services (type ClusterIP ou NodePort selon besoin)
- Ingress pour exposer api-gateway
- Autoscaling (HPA sur CPU pour inventory-app et api-gateway)
- Secrets pour les mots de passe (interdiction de les écrire dans les YAMLs hors Secret)
4) écrire un orchestrator.sh avec create, start, stop pour gérer l'infra.
5) documenter tout dans un README.md.

## Structure
```
.
├── docker-compose.yaml
├── k3s_token
├── manifests
│   ├── api-gateway-app
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   └── service.yaml
│   ├── billing-app
│   │   ├── service.yaml
│   │   └── statefulset.yaml
│   ├── databases
│   │   ├── billing-db.yaml
│   │   └── inventory-db.yaml
│   ├── ingress
│   │   └── ingress.yaml
│   ├── inventory-app
│   │   ├── deployment.yaml
│   │   ├── hpa.yaml
│   │   └── service.yaml
│   ├── rabbitmq
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── secrets
│       ├── billing-db-secret.yaml
│       ├── inventory-db-secret.yaml
│       └── rabbitmq-secret.yaml
├── orchestrator.sh
├── push.sh
├── README.md
├── scripts
│   ├── build-images.sh
│   ├── deploy-all.sh
│   └── push-images.sh
├── srcs
│   ├── api-gateway-app
│   │   ├── app
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── server.py
│   ├── billing-app
│   │   ├── app
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── server.py
│   ├── inventory-app
│   │   ├── app
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── server.py
│   ├── postgres-db
│   │   ├── Dockerfile
│   │   └── tools
│   └── rabbitmq
│       ├── Dockerfile
│       └── tools
└── Vagrantfile
└── .git
└── .gitignore
└── .env.exemple
```

## Utilisation:
- ./orchestrator.sh
- vagrant ssh master
- vagrant/scripts/./deploy-all.sh

## Code
1) utiliser kubectl sans sudo
- sudo chmod 644 /etc/rancher/k3s/k3s.yaml
- export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
2) déplouter