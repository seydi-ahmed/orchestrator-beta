# # Vagrantfile complet pour K3s master/agent avec token partagé
# Vagrant.configure("2") do |config|
#     config.vm.box = "ubuntu/focal64"
  
#     # Master Node
#     config.vm.define "master" do |master|
#       master.vm.hostname = "master"
#       master.vm.network "private_network", ip: "192.168.56.10"
#       master.vm.provider "virtualbox" do |vb|
#         vb.memory = 2048
#         vb.cpus = 2
#       end
#       master.vm.provision "shell", inline: <<-SHELL
#         echo "[+] Installing K3s on master..."
#         curl -sfL https://get.k3s.io | sh -
#         echo "[+] Exporting node token..."
#         sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token
#       SHELL
#     end
  
#     # Agent Node
#     config.vm.define "agent" do |agent|
#       agent.vm.hostname = "agent"
#       agent.vm.network "private_network", ip: "192.168.56.11"
#       agent.vm.provider "virtualbox" do |vb|
#         vb.memory = 2048
#         vb.cpus = 2
#       end
#       agent.vm.provision "shell", inline: <<-SHELL
#         echo "[+] Waiting for master token..."
#         while [ ! -f /vagrant/k3s_token ]; do sleep 2; done
#         echo "[+] Installing K3s agent..."
#         curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$(cat /vagrant/k3s_token) sh -
#       SHELL
#     end
  
#     config.vm.post_up_message = "K3s cluster is now running! Use ./orchestrator.sh to manage it."
#   end
  

# -*- mode: ruby -*-
# vi: set ft=ruby :

master_ip = "192.168.56.10"
agent_ip = "192.168.56.11"

# Extra parameters in INSTALL_K3S_EXEC variable because of
# K3s picking up the wrong interface when starting server and agent
# https://github.com/alexellis/k3sup/issues/306

master_script = <<-SHELL
    sudo -i
    apk add curl
    # export INSTALL_K3S_EXEC="--bind-address=#{master_ip} \
    #   --node-external-ip=#{master_ip} \
    #   --flannel-iface=eth1"
    export INSTALL_K3S_EXEC="--disable=traefik --bind-address=#{master_ip} \
      --node-external-ip=#{master_ip} \
      --flannel-iface=eth1"
    curl -sfL https://get.k3s.io | sh -
    echo "Waiting for K3s server to be ready..."
    until [ -f /var/lib/rancher/k3s/server/token ]; do
      sleep 2
    done
    cp /var/lib/rancher/k3s/server/token /vagrant_shared
    chmod 644 /etc/rancher/k3s/k3s.yaml
    cp /etc/rancher/k3s/k3s.yaml /vagrant_shared
    cp /etc/rancher/k3s/k3s.yaml /
    SHELL

agent_script = <<-SHELL
    sudo -i
    apk add curl
    export K3S_TOKEN_FILE=/vagrant_shared/token
    export K3S_URL=https://#{master_ip}:6443
    export INSTALL_K3S_EXEC="--flannel-iface=eth1"
    curl -sfL https://get.k3s.io | sh -
    SHELL

    Vagrant.configure("2") do |config|
      config.vm.box = "generic/alpine314"
    
      config.vm.define "master", primary: true do |master|
        master.vm.network "private_network", ip: master_ip
        master.vm.synced_folder ".", "/vagrant_shared"
        master.vm.hostname = "master"
        master.vm.provider "virtualbox" do |vb|
          vb.memory = "2048"
          vb.cpus = "2"
        end
        master.vm.provision "shell", inline: master_script
      end
    
      config.vm.define "agent" do |agent|
        agent.vm.network "private_network", ip: agent_ip
        # Attention : plus de synced_folder ici !
        agent.vm.hostname = "agent"
        agent.vm.provider "virtualbox" do |vb|
          vb.memory = "1024"
          vb.cpus = "1"
        end
        agent.vm.provision "shell", inline: agent_script, run: "always"
      end
    end
    