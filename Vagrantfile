Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"
    
    # Configuration des dossiers partagés
    config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
    config.vm.synced_folder ".shared", "/shared", create: true, owner: "vagrant", group: "vagrant"
  
    # Configuration du nœud master
    config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: "192.168.56.10"
      
      master.vm.provider "virtualbox" do |vb|
        vb.memory = 3072  # 3GB RAM
        vb.cpus = 2
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--ioapic", "on"]
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      end
  
      master.vm.provision "shell", inline: <<-SHELL
        # Mise à jour système
        sudo apt-get update -y
        sudo apt-get upgrade -y
        
        # Installation des dépendances
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg net-tools
  
        # Installation de Helm
        curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
        echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
        sudo apt-get update -y
        sudo apt-get install -y helm
  
        # Pré-configuration réseau
        sudo modprobe br_netfilter
        sudo modprobe overlay
        echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf
        echo "overlay" | sudo tee /etc/modules-load.d/overlay.conf
        sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
  
        # Installation de K3s avec configuration explicite
        curl -sfL https://get.k3s.io | \
          INSTALL_K3S_EXEC="--disable traefik --write-kubeconfig-mode 644 --tls-san 192.168.56.10 --node-ip 192.168.56.10" \
          INSTALL_K3S_VERSION="v1.32.3+k3s1" \
          K3S_KUBECONFIG_MODE="644" \
          sh -
  
        # Configuration de l'accès
        mkdir -p /home/vagrant/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
        sudo chown vagrant:vagrant /home/vagrant/.kube/config
        echo "export KUBECONFIG=~/.kube/config" >> /home/vagrant/.bashrc
        
        # Régénération du token partagé
        sudo cat /var/lib/rancher/k3s/server/node-token | sudo tee /shared/k3s_token
        sudo chmod 644 /shared/k3s_token
  
        # Attente que l'API soit disponible
        until curl -sf https://192.168.56.10:6443; do sleep 5; done
      SHELL
    end
  
    # Configuration du nœud agent
    config.vm.define "agent" do |agent|
      agent.vm.hostname = "agent"
      agent.vm.network "private_network", ip: "192.168.56.11"
      
      agent.vm.provider "virtualbox" do |vb|
        vb.memory = 2048  # 2GB RAM
        vb.cpus = 1
        vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      end
  
      agent.vm.provision "shell", inline: <<-SHELL
        # Pré-configuration réseau
        sudo modprobe br_netfilter
        sudo modprobe overlay
        sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
  
        # Installation des dépendances
        sudo apt-get update -y
        sudo apt-get install -y curl
  
        # Attente active du master
        echo "Waiting for master to be fully ready..."
        until curl -sf https://192.168.56.10:6443; do sleep 10; done
        while [ ! -f /shared/k3s_token ]; do sleep 5; done
  
        # Installation de l'agent avec timeout
        timeout 10m bash -c '
          curl -sfL https://get.k3s.io | \
            K3S_URL=https://192.168.56.10:6443 \
            K3S_TOKEN_FILE=/shared/k3s_token \
            INSTALL_K3S_VERSION="v1.32.3+k3s1" \
            INSTALL_K3S_EXEC="--node-ip 192.168.56.11 --flannel-iface=enp0s8" \
            sh -
        ' || echo "Installation timed out, check logs with: journalctl -u k3s-agent -f"
  
        # Vérification finale
        sudo systemctl status k3s-agent --no-pager
      SHELL
    end
  
    config.vm.post_up_message = <<-MESSAGE
  Cluster K3s déployé avec succès!
  
  Commandes utiles:
  1. Se connecter au master: vagrant ssh master
  2. Vérifier les noeuds: kubectl get nodes
  3. Déployer les applications: cd /vagrant && ./scripts/deploy-all.sh
  
  Accès depuis l'hôte:
  1. Copier le kubeconfig: scp -P 2222 vagrant@127.0.0.1:~/.kube/config ~/.kube/k3s-config
  2. Exporter le config: export KUBECONFIG=~/.kube/k3s-config
  3. Modifier l'IP: sed -i 's/127.0.0.1/192.168.56.10/' ~/.kube/k3s-config
  MESSAGE
  end