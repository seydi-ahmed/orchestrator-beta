# -*- mode: ruby -*-
# vi: set ft=ruby :

master_ip = "192.168.56.10"
agent_ip = "192.168.56.11"

master_script = <<-SHELL
    sudo -i
    
    # Configure DNS to use Cloudflare for better reliability
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    
    # Update system and install dependencies
    apt-get update

    # **********************posgre**************************

    # Install and configure PostgreSQL
    apt-get install -y postgresql postgresql-client
    systemctl enable postgresql
    systemctl start postgresql

    # Create databases and user with both passwords
    sudo -u postgres psql <<EOSQL
-- Create main user with inventory password
CREATE USER user01 WITH PASSWORD 'postgres';

-- Create databases
CREATE DATABASE inventory_db OWNER user01;
CREATE DATABASE billing_db OWNER user01;

-- Update password for billing access
ALTER USER user01 WITH PASSWORD 'password';
EOSQL

    # Allow remote connections
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/*/main/pg_hba.conf
    systemctl restart postgresql

    echo "=== PostgreSQL setup complete ==="

    # **********************posgre**************************

    apt-get install -y curl iptables iproute2 net-tools jq

    # Create local-path provisioner directory required by Rancher's provisioner
    # mkdir -p /opt/local-path-provisioner
    # chmod -R 777 /opt/local-path-provisioner

    
    # Network configuration checks
    echo "=== Network Configuration ==="
    ip -4 a show enp0s8 | grep inet
    ip route
    ping -c 3 #{master_ip} -I enp0s8 || echo "Ping failed"
    
    # Disable firewall and clear iptables
    ufw disable
    iptables -F
    iptables -X
    
    # Install K3s with specific version and debug options
    export INSTALL_K3S_VERSION="v1.28.5+k3s1"  # Using a known stable version
    export INSTALL_K3S_EXEC="\
      --bind-address=#{master_ip} \
      --node-external-ip=#{master_ip} \
      --flannel-iface=enp0s8 \
      --write-kubeconfig-mode=644 \
      --tls-san=#{master_ip} \
      --node-ip=#{master_ip} \
      --advertise-address=#{master_ip}"
    
    echo "=== Installing K3s with command ==="
    echo "INSTALL_K3S_EXEC=${INSTALL_K3S_EXEC}"
    
    # Download and install with retry logic
    for i in {1..5}; do
      echo "Attempt $i to install K3s..."
      curl -sfL https://get.k3s.io | sh -s - --debug && break
      sleep 10
    done
    
    # Check service status
    echo "=== K3s Service Status ==="
    systemctl status k3s.service || journalctl -u k3s.service -xe
    
    # Wait for K3s to be ready with timeout
    timeout 120 bash -c 'until [ -f /var/lib/rancher/k3s/server/token ]; do
      echo "Waiting for K3s token..."
      systemctl status k3s.service || journalctl -u k3s.service -xe
      sleep 5
    done' || echo "Timeout waiting for token"
    
    # Copy configuration files
    
    cp /var/lib/rancher/k3s/server/token /vagrant
    chmod 644 /etc/rancher/k3s/k3s.yaml
    cp /etc/rancher/k3s/k3s.yaml /vagrant

    
    echo "=== K3s Installation Complete ==="
    kubectl get nodes -o wide
SHELL

# Modifiez la partie agent_script comme suit :
agent_script = <<-SHELL
    sudo -i
    
    # Configure DNS
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    
    # Install dependencies
    apt-get update
    apt-get install -y curl iptables iproute2 net-tools jq

    # Create local-path provisioner directory required by Rancher's provisioner
    # mkdir -p /opt/local-path-provisioner
    # chmod -R 777 /opt/local-path-provisioner
    
    # Network checks
    echo "=== Network Configuration ==="
    ip -4 a show enp0s8 | grep inet
    ip route
    ping -c 3 #{master_ip} || echo "Ping failed"
    
    # Disable firewall
    ufw disable
    iptables -F
    iptables -X
    
    # Wait for master token (using correct shared folder path)
    echo "Waiting for master token file..."
    until [ -f /vagrant/token ]; do
      echo "Token not found, checking master connectivity..."
      if ! ping -c 3 #{master_ip}; then
        echo "ERROR: Cannot reach master at #{master_ip}"
        exit 1
      fi
      sleep 5
    done
    
    # Verify token content
    echo "Token content:"
    cat /vagrant/token
    
    # Join cluster with retry logic
    export K3S_TOKEN=$(cat /vagrant/token)
    export K3S_URL=https://#{master_ip}:6443
    export INSTALL_K3S_EXEC="--flannel-iface=enp0s8 --node-ip=#{agent_ip}"
    
    echo "=== Joining cluster ==="
    echo "K3S_URL=${K3S_URL}"
    echo "NODE_IP=#{agent_ip}"
    
    for i in {1..5}; do
      echo "Attempt $i to join cluster..."
      curl -sfL https://get.k3s.io | sh - && break
      sleep 10
    done
    
    echo "=== Agent Installation Complete ==="
    systemctl status k3s-agent || journalctl -u k3s-agent -xe
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false

# Master configuration
config.vm.define "master", primary: true do |master|
  master.vm.network "private_network", ip: master_ip, auto_config: true
  master.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=777,fmode=666"]
  master.vm.hostname = "master"
  
  master.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = "2"
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end

  # Crée le dossier requis pour le local-path-provisioner sur le master uniquement
  master.vm.provision "shell", inline: <<-SHELL
    sudo mkdir -p /var/lib/rancher/k3s/storage
    sudo chmod -R 777 /var/lib/rancher/k3s/storage
  SHELL

  master.vm.provision "shell", inline: master_script
end


  # Agent configuration reste inchangé
  config.vm.define "agent" do |agent|
    agent.vm.network "private_network", ip: agent_ip, auto_config: true
    agent.vm.hostname = "agent"
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end
    agent.vm.provision "shell", inline: agent_script, run: "always"
  end
end