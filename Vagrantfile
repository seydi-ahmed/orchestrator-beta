VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    master.vm.provision "shell", inline: <<-SHELL
      curl -sfL https://get.k3s.io | sh -s - server --node-taint CriticalAddonsOnly=true:NoExecute
    SHELL
  end

  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent"
    agent.vm.network "private_network", ip: "192.168.56.11"
    agent.vm.provision "shell", inline: <<-SHELL
      K3S_TOKEN=$(ssh vagrant@192.168.56.10 sudo cat /var/lib/rancher/k3s/server/node-token)
      curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$K3S_TOKEN sh -s -
    SHELL
  end
end