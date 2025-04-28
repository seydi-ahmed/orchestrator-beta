# -*- mode: ruby -*-
# vi: set ft=ruby :

master_ip = "192.168.56.10"
agent_ip = "192.168.56.11"

# Extra parameters in INSTALL_K3S_EXEC variable because of
# K3s picking up the wrong interface when starting server and agent
# https://github.com/alexellis/k3sup/issues/306

master_script = <<-SHELL
    sudo -i
    apt-get update
    apt-get install -y curl iptables iproute2 net-tools
    
    # Disable firewall temporarily
    ufw disable
    
    # Clear any existing iptables rules
    iptables -F
    iptables -X
    
    # Verify network interfaces
    echo "Network interfaces:"
    ip a
    echo "Routing table:"
    ip route
    
    export INSTALL_K3S_EXEC="--disable=traefik --bind-address=#{master_ip} \
      --node-external-ip=#{master_ip} \
      --flannel-iface=eth1 \
      --write-kubeconfig-mode=644 \
      --tls-san=#{master_ip}"
    
    curl -sfL https://get.k3s.io | sh -s - --debug
    
    echo "Checking K3s service status..."
    systemctl status k3s.service || journalctl -u k3s.service -xe
    
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
    apt-get update
    apt-get install -y curl iptables iproute2
    export K3S_TOKEN_FILE=/vagrant_shared/token
    export K3S_URL=https://#{master_ip}:6443
    export INSTALL_K3S_EXEC="--flannel-iface=eth1"
    curl -sfL https://get.k3s.io | sh -
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  # Configuration de la machine master
  config.vm.define "master", primary: true do |master|
    master.vm.network "private_network", ip: master_ip
    master.vm.synced_folder ".", "/vagrant_shared"
    master.vm.hostname = "master"
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = "2"
    end
    master.vm.provision "shell", inline: master_script
  end

  # Configuration de la machine agent
  config.vm.define "agent" do |agent|
    agent.vm.network "private_network", ip: agent_ip
    agent.vm.hostname = "agent"
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
    end
    agent.vm.provision "shell", inline: agent_script, run: "always"
  end
end
