git config --global user.email "seydiahmedelcheikh@gmail.com"
git config --global user.name "mouhameddiouf"
git config credential.helper store
git add .
git commit -m "    Configuration réseau plus robuste :

        Interface spécifiée explicitement (enp0s8)

        Configuration DNS améliorée

        Vérifications réseau supplémentaires

    Installation de K3s plus fiable :

        Version spécifique de K3s (v1.28.5+k3s1)

        Logique de réessai pour le téléchargement

        Options d'adresse IP supplémentaires

    Meilleure gestion des erreurs :

        Timeout pour l'attente du token

        Journalisation améliorée

        Vérification du statut du service

    Optimisations VirtualBox :

        Type d'interface réseau en virtio

        Options de montage des dossiers partagés

    Ressources ajustées :

        Master : 4GB RAM

        Agent : 2GB RAM"
git push --force