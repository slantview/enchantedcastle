#!/bin/bash

set -e

# Load K3S_TOKEN from 1Password if not in .env
if ! grep -q "K3S_TOKEN=" .env; then
    echo "Loading K3S_TOKEN from 1Password..."
    K3S_TOKEN=$(op read "op://Personal/Default/K3S_TOKEN")
    echo "K3S_TOKEN=$K3S_TOKEN" >> .env
fi

echo "Starting k3s cluster..."
docker compose up -d

echo "Waiting for k3s server to be ready..."
sleep 10

echo "Retrieving kubeconfig..."
if [ -f kubeconfig/kubeconfig.yaml ]; then
    echo "✓ k3s cluster is ready!"
    echo ""
    echo "To use kubectl, set your kubeconfig:"
    echo "  export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml"
    echo ""
    echo "Then verify the cluster:"
    echo "  kubectl cluster-info"
    echo "  kubectl get nodes"
else
    echo "✗ Kubeconfig not found. The container may still be initializing."
    echo "  Check logs with: docker compose logs k3s-server"
fi
