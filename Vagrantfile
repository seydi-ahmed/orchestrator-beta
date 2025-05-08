# -*- mode: ruby -*-
# vi: set ft=ruby :

master_ip = "192.168.56.10"
agent_ip = "192.168.56.11"

coredns_fix_script = <<-SHELL
    # Configuration stable de CoreDNS (version optimisée)
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        forward . /etc/resolv.conf {
           prefer_udp
           policy sequential
        }
        cache 30
        reload 2s
        loadbalance round_robin
    }
EOF

    # Redémarrage forcé avec vérification
    kubectl rollout restart deployment coredns -n kube-system
    kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=120s

    # Script de maintenance automatique
    cat > /usr/local/bin/ensure-dns <<'EOL'
#!/bin/bash
# Vérifie et corrige la configuration CoreDNS si nécessaire
current_config=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}')
if grep -q "loop" <<< "$current_config"; then
  kubectl get cm coredns -n kube-system -o yaml | \
    sed '/loop/d' | \
    kubectl apply -f -
  kubectl rollout restart deployment coredns -n kube-system
fi
EOL

    chmod +x /usr/local/bin/ensure-dns
    echo "@reboot root /usr/local/bin/ensure-dns && /usr/local/bin/ensure-dns" > /etc/cron.d/k3s-dns-maintenance
SHELL

master_script = <<-SHELL
    # sudo -i
    
    # Configuration DNS robuste
    echo "nameserver 1.1.1.1" | tee /etc/resolv.conf
    echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
    chattr +i /etc/resolv.conf  # Empêche la modification par DHCP

    # Mise à jour système
    apt-get update -y
    apt-get install -y curl jq net-tools git

    # Configuration réseau
    # ip link set enp0s8 up
    # ip addr add #{master_ip}/24 dev enp0s8

    # ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

    # Installation K3s avec paramètres optimisés
    export INSTALL_K3S_VERSION="v1.28.5+k3s1"
    export INSTALL_K3S_EXEC="\\
      --cluster-init \\
      --node-ip=#{master_ip} \\
      --node-external-ip=#{master_ip} \\
      --flannel-iface=enp0s8 \\
      --disable traefik \\
      --disable servicelb \\
      --kubelet-arg='cloud-provider=external' \\
      --resolv-conf=/etc/resolv.conf \\
      --tls-san=#{master_ip}"

    curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

    # Attente de l'initialisation
    until [ -f /etc/rancher/k3s/k3s.yaml ]; do
      echo "En attente de l'initialisation de K3s..."
      sleep 5
    done

    # Application de la solution CoreDNS
    #{coredns_fix_script}

    # Préparation des accès
    cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
    sed -i "s/127.0.0.1/#{master_ip}/g" /vagrant/k3s.yaml
    chmod 644 /vagrant/k3s.yaml
    cp /var/lib/rancher/k3s/server/node-token /vagrant/

    echo "=== Configuration master terminée ==="
SHELL

agent_script = <<-SHELL
    sudo -i
    
    # Configuration DNS identique au master
    echo "nameserver 1.1.1.1" | tee /etc/resolv.conf
    echo "nameserver 8.8.8.8" | tee -a /etc/resolv.conf
    # chattr +i /etc/resolv.conf

    # Attente du master
    until ping -c 1 #{master_ip}; do
      echo "En attente du master..."
      sleep 5
    done

    # Jointure du cluster
    export K3S_TOKEN=$(cat /vagrant/node-token)
    export K3S_URL=https://#{master_ip}:6443
    export INSTALL_K3S_EXEC="\\
      --node-ip=#{agent_ip} \\
      --flannel-iface=enp0s8 \\
      --resolv-conf=/etc/resolv.conf"

    curl -sfL https://get.k3s.io | sh -

    echo "=== Agent prêt ==="
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false

  # Configuration VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.customize [
      "modifyvm", :id,
      "--natdnshostresolver1", "on",
      "--natdnsproxy1", "on",
      "--nictype1", "virtio",
      "--nictype2", "virtio",
      "--cableconnected2", "on"
    ]
  end

  # Master
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: master_ip
    master.vm.synced_folder ".", "/vagrant", type: "virtualbox"

    master.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end

    master.vm.provision "shell", inline: master_script
  end

  # Agent
  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent"
    agent.vm.network "private_network", ip: agent_ip

    agent.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end

    agent.vm.provision "shell", inline: agent_script
  end
end