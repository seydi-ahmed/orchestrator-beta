# -*- mode: ruby -*-
# vi: set ft=ruby :

master_ip = "192.168.56.10"
agent_ip = "192.168.56.11"

coredns_fix_script = <<-SHELL
# Apply CoreDNS config fix
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

kubectl rollout restart deployment coredns -n kube-system
kubectl wait --for=condition=ready pod -l k8s-app=kube-dns -n kube-system --timeout=120s

# Ensure-dns auto-heal
cat > /usr/local/bin/ensure-dns <<'EOL'
#!/bin/bash
current_config=$(kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}')
if grep -q "loop" <<< "$current_config"; then
  kubectl get cm coredns -n kube-system -o yaml | sed '/loop/d' | kubectl apply -f -
  kubectl rollout restart deployment coredns -n kube-system
fi
EOL

chmod +x /usr/local/bin/ensure-dns
echo "@reboot root /usr/local/bin/ensure-dns" > /etc/cron.d/k3s-dns-maintenance
SHELL

master_script = <<-SHELL
sudo -i

# Configure reliable DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# System update and tools
apt-get update
apt-get install -y curl jq net-tools iptables iproute2 ufw

# Disable firewall
ufw disable
iptables -F
iptables -X

# Setup K3s
export INSTALL_K3S_VERSION="v1.28.5+k3s1"
export INSTALL_K3S_EXEC="\
  --cluster-init \
  --bind-address=#{master_ip} \
  --node-ip=#{master_ip} \
  --node-external-ip=#{master_ip} \
  --advertise-address=#{master_ip} \
  --flannel-iface=enp0s8 \
  --disable traefik \
  --disable servicelb \
  --kubelet-arg=cloud-provider=external \
  --resolv-conf=/etc/resolv.conf \
  --tls-san=#{master_ip} \
  --write-kubeconfig-mode=644"

for i in {1..5}; do
  echo "Attempt $i to install K3s..."
  curl -sfL https://get.k3s.io | sh -s - --debug && break
  sleep 10
done

# Wait for readiness
timeout 120 bash -c 'until [ -f /etc/rancher/k3s/k3s.yaml ]; do
  echo "Waiting for K3s config..."
  sleep 5
done'

# Fix CoreDNS
#{coredns_fix_script}

# Share K3s config with host and agent
cp /etc/rancher/k3s/k3s.yaml /vagrant
sed -i "s/127.0.0.1/#{master_ip}/g" /vagrant/k3s.yaml
cp /var/lib/rancher/k3s/server/token /vagrant/token
chmod 644 /vagrant/k3s.yaml /vagrant/token
SHELL

agent_script = <<-SHELL
sudo -i

# Configure DNS
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

apt-get update
apt-get install -y curl jq net-tools iptables iproute2 ufw

# Disable firewall
ufw disable
iptables -F
iptables -X

# Wait for token
echo "Waiting for master token..."
until [ -f /vagrant/token ]; do
  echo "Token not found, retrying..."
  sleep 5
done

export K3S_TOKEN=$(cat /vagrant/token)
export K3S_URL=https://#{master_ip}:6443
export INSTALL_K3S_EXEC="--node-ip=#{agent_ip} --flannel-iface=enp0s8 --resolv-conf=/etc/resolv.conf"

for i in {1..5}; do
  echo "Joining cluster (attempt $i)..."
  curl -sfL https://get.k3s.io | sh - && break
  sleep 10
done
SHELL

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = false

  # Master
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: master_ip, auto_config: true
    master.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=777,fmode=666"]
    master.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    master.vm.provision "shell", inline: master_script
  end

  # Agent
  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent"
    agent.vm.network "private_network", ip: agent_ip, auto_config: true
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
      vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
      vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end
    agent.vm.provision "shell", inline: agent_script, run: "always"
  end
end
