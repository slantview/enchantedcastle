#!/bin/bash
set -e

echo "Installing k3s on karuna..."

# Install k3s as a server (control plane)
curl -sfL https://get.k3s.io | sh -s - server \
  --tls-san=karuna.enchantedcastle.house \
  --tls-san=karuna \
  --node-label hostname=karuna \
  --node-label cluster=karuna \
  --write-kubeconfig-mode 644

echo "Waiting for k3s to be ready..."
sleep 10

# Verify installation
sudo k3s kubectl get nodes

echo ""
echo "✓ k3s installed successfully on karuna"
echo "Kubeconfig available at: /etc/rancher/k3s/k3s.yaml"
