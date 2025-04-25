#!/bin/bash

set -e

case "$1" in
  create)
    echo "[+] Creating K3s cluster..."
    vagrant up
    echo "[+] Copying kubeconfig..."
    mkdir -p ~/.kube
    vagrant ssh master -c "sudo cat /etc/rancher/k3s/k3s.yaml" > ~/.kube/config
    sed -i 's/127.0.0.1/192.168.56.10/' ~/.kube/config
    echo "[✓] Cluster created"
    ;;
  start)
    echo "[+] Starting cluster..."
    vagrant up
    ;;
  stop)
    echo "[+] Stopping cluster..."
    vagrant halt
    ;;
  destroy)
    echo "[!] Destroying cluster..."
    vagrant destroy -f
    ;;
  status)
    echo "[i] Cluster status:"
    vagrant status
    ;;
  *)
    echo "Usage: ./orchestrator.sh {create|start|stop|destroy|status}"
    ;;
esac
