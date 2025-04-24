# Vagrantfile complet pour K3s master/agent avec token partagé
Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/focal64"
  
    # Master Node
    config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: "192.168.56.10"
      master.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 2
      end
      master.vm.provision "shell", inline: <<-SHELL
        echo "[+] Installing K3s on master..."
        curl -sfL https://get.k3s.io | sh -
        echo "[+] Exporting node token..."
        sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/k3s_token
      SHELL
    end
  
    # Agent Node
    config.vm.define "agent" do |agent|
      agent.vm.hostname = "agent"
      agent.vm.network "private_network", ip: "192.168.56.11"
      agent.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 2
      end
      agent.vm.provision "shell", inline: <<-SHELL
        echo "[+] Waiting for master token..."
        while [ ! -f /vagrant/k3s_token ]; do sleep 2; done
        echo "[+] Installing K3s agent..."
        curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$(cat /vagrant/k3s_token) sh -
      SHELL
    end
  
    config.vm.post_up_message = "K3s cluster is now running! Use ./orchestrator.sh to manage it."
  end
  