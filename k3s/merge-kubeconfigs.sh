#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECONFIG_DIR="$SCRIPT_DIR/kubeconfig"
MERGED_CONFIG="$KUBECONFIG_DIR/merged-kubeconfig.yaml"

mkdir -p "$KUBECONFIG_DIR"

echo "Creating merged kubeconfig..."

# Extract karuna kubeconfig
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo "✓ Extracting karuna kubeconfig..."
    sudo cat /etc/rancher/k3s/k3s.yaml | \
        sed 's/127.0.0.1/karuna.enchantedcastle.house/g' | \
        sed 's/: default$/: karuna/g' | \
        sed 's/name: default$/name: karuna/g' | \
        sed 's/current-context: default$/current-context: karuna/g' \
        > "$KUBECONFIG_DIR/karuna.yaml"
else
    echo "✗ k3s not installed on karuna. Run ./install-karuna.sh first"
    exit 1
fi

# Check for tower kubeconfig
if [ -f "$KUBECONFIG_DIR/kubeconfig.yaml" ]; then
    echo "✓ Found tower kubeconfig"
    # Rename contexts in tower config
    cat "$KUBECONFIG_DIR/kubeconfig.yaml" | \
        sed 's/: default$/: tower/g' | \
        sed 's/name: default$/name: tower/g' | \
        sed 's/current-context: default$/current-context: tower/g' \
        > "$KUBECONFIG_DIR/tower.yaml"
else
    echo "✗ Tower kubeconfig not found. Start tower cluster first with ./start.sh"
    exit 1
fi

# Merge configs
KUBECONFIG="$KUBECONFIG_DIR/karuna.yaml:$KUBECONFIG_DIR/tower.yaml" \
    kubectl config view --flatten > "$MERGED_CONFIG"

# Set default context to karuna
kubectl --kubeconfig="$MERGED_CONFIG" config use-context karuna

echo ""
echo "✓ Merged kubeconfig created: $MERGED_CONFIG"
echo ""
echo "Test with:"
echo "  export KUBECONFIG=$MERGED_CONFIG"
echo "  kubectl config get-contexts"
echo "  kubectl get nodes"
echo ""
echo "Switch clusters:"
echo "  kubectl config use-context tower"
echo "  kubectl config use-context karuna"
