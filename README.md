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
2) docker-pusher tes images sur Docker Hub.
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
├── Dockerfiles/                      # Tous tes Dockerfiles ici
│   ├── api-gateway-app.Dockerfile
│   ├── billing-app.Dockerfile
│   ├── inventory-app.Dockerfile
│   ├── postgres-db.Dockerfile
│   └── rabbitmq.Dockerfile
│
├── Manifests/                        # Tous tes fichiers YAML Kubernetes ici
│   ├── api-gateway/
│   ├── billing-app/
│   ├── inventory-app/
│   ├── databases/
│   ├── rabbitmq/
│   └── secrets/
│
├── Scripts/                          # Tes scripts bash
│   ├── orchestrator.sh
│   └── provision.sh                  # Script provision pour Vagrant
│
├── Vagrantfile
├── README.md                         # Documentation complète
└── srcs/                             # Code source des apps
    ├── api-gateway-app/
    ├── billing-app/
    ├── inventory-app/
```

## Manifests Kubernetes à créer
1) Deployments & StatefulSets
- api-gateway ➜ Deployment + HPA
- inventory-app ➜ Deployment + HPA
- billing-app ➜ StatefulSet
- postgres-inventory-db ➜ StatefulSet + PVC
- postgres-billing-db ➜ StatefulSet + PVC
- rabbitmq ➜ StatefulSet + PVC
2) Services
- ClusterIP pour chaque app interne
- NodePort ou Ingress pour api-gateway
3) Ingress (expose ton API Gateway via un domaine ou IP publique)
- api-gateway-ingress.yaml
4) Secrets
- db-secrets.yaml : mots de passe PostgreSQL + RabbitMQ

## Création de 4 fichiers pour pousser kles images dans Docker Hub, pour orchestrer les machines:
- push_docker_hub.sh
- orchestrator.sh
- provision.sh
- Vagrantfile

## Générer les manifest Kubernetes
1) Secrets
- Créer un manifest Manifests/secrets/secrets.yaml contenant:
- Les logins/passwords de:
    - PostgreSQL (inventory + billing)
    - RabbitMQ
- But: Sécuriser les infos sensibles
2) Databases (StatefulSets + Services + PVCs)
- Créer dans Manifests/databases/:
    - postgres-inventory.yaml
    - postgres-billing.yaml
- But: Déployer des bases avec stockage persistant (StatefulSet)
    - services pour exposer en cluster.
3) RabbitMQ (StatefulSet + Service + PVC)
- Créer dans Manifests/rabbitmq/:
    - rabbitmq.yaml
- But : File de messages partagée avec stockage
4) Applications
- Créer pour chaque app un sous-dossier :
    - Manifests/api-gateway/
    - Manifests/inventory-app/
    - Manifests/billing-app/
5) Ingress (api-gateway only)
- Créer Manifests/api-gateway/ingress.yaml :
    - Expose ton api-gateway au monde extérieur via un Ingress
    - (optionnel : domaine local api.local avec /etc/hosts pour test)

## Déploiement avec orchestrator.sh
```
./orchestrator.sh create     # Lance les VMs
./orchestrator.sh deploy     # Applique tous les manifests
kubectl get pods -A          # Vérifie que tout roule
```

## Prérequis
- Assure-toi que tu as toutes les prérequis:
    - Vagrant installé sur ta machine.
    - VirtualBox (ou un autre provider compatible) pour la virtualisation.
    - Docker installé pour build et push les images.
    - kubectl installé pour interagir avec ton cluster K3s.
    - Un compte Docker Hub pour pousser les images.

## Préparation de l'environment de travail
1) Vagrantfile & Provisioning:
- Mets en place tes VMs avec Vagrant.
- Dans ton dossier racine du projet, utilise le fichier Vagrantfile:
- Lance la commande pour créer et démarrer les VMs:
```
vagrant up
```

- vagrant ssh master
```
cd /vagrant
kubectl apply -f Manifests/secrets/
kubectl apply -f Manifests/databases/
kubectl apply -f Manifests/rabbitmq/
kubectl apply -f Manifests/apps/
kubectl apply -f Manifests/ingress/
```
- pas obligatoire. juste pour utiliser kubectl sans sudo
```
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```
- vérification
    - kubectl run -it --rm busybox --image=busybox --restart=Never -- /bin/sh
    - ping billing-db

2) Build et push des Docker images :
- Place tes Dockerfiles dans le dossier Dockerfiles comme tu l’as fait.
- Exécute ton script push_docker_hub.sh pour builder et envoyer les images sur Docker Hub :
```
./push_docker_hub.sh
```
- Assure-toi que les images sont bien présentes sur Docker Hub avec la commande suivante :
```
docker images
```
3) Démarre le cluster K3s :
- Démarre les VMs et K3s :
- Exécute la commande pour démarrer ton cluster K3s avec Vagrant et tes VMs :
```
./orchestrator.sh start
```
- Vérifie que les nœuds du cluster sont bien connectés :
```
kubectl get nodes
```
4) Déployer les manifests Kubernetes:
- Applique les manifests:
- Maintenant que ton cluster est en ligne, déploie les différentes ressources Kubernetes avec le script orchestrator:
```
./orchestrator.sh deploy
```
- Ce script va appliquer tous les manifests que tu as créés pour les secrets, les bases de données, RabbitMQ, les apps, et l'Ingress.
5) Tester l’accès à l’API Gateway :
- Modifie ton fichier /etc/hosts pour ajouter api.localhost:
    - Ouvre le fichier /etc/hosts avec un éditeur de texte et ajoute cette ligne:
```
127.0.0.1 api.localhost
```
- Accède à ton API Gateway via ton navigateur ou outil préféré en visitant :
```
http://api.localhost:3000
```
6) Surveille le fonctionnement:
- Vérification des pods et services:
    - Tu peux vérifier si tout fonctionne bien en exécutant:
```
kubectl get pods
kubectl get services
```
- Logs des services :
    - Pour suivre les logs de ton api-gateway, par exemple :
```
kubectl logs -f <pod-name> -n <namespace>
```
7) Arrêter et nettoyer le cluster :
- Si tu veux arrêter ton cluster et les VMs :
```
./orchestrator.sh stop
```
- Pour supprimer le cluster et les VMs (nettoyage complet) :
```
./orchestrator.sh delete
```









