# K3s Multi-Cluster Quick Start

## Setup Complete! ✓

You now have two independent k3s clusters:
- **karuna** (`karuna.enchantedcastle.house:6443`) - Native k3s on this machine
- **tower** (`tower.enchantedcastle.house:6443`) - k3s in Docker on Unraid

## Usage

### Switch between clusters
```bash
kubectl config use-context tower
kubectl config use-context karuna
```

### View all contexts
```bash
kubectl config get-contexts
```

### Query specific cluster
```bash
kubectl --context=tower get pods -A
kubectl --context=karuna get nodes
```

### Deploy to specific node using labels
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  nodeSelector:
    hostname: tower  # or hostname: karuna
  containers:
  - name: app
    image: nginx
```

## Management

### Restart tower cluster
```bash
export DOCKER_HOST=tcp://192.168.4.47:2375
docker compose restart k3s-server
```

### Restart karuna cluster
```bash
sudo systemctl restart k3s
```

### Update credentials in 1Password
```bash
# Update kubeconfig
./merge-kubeconfigs.sh
op document edit "k3s-merged-kubeconfig" --vault Personal kubeconfig/merged-kubeconfig.yaml

# Update token
op item edit "K3s Token" --vault Personal "K3S_TOKEN[password]=NEW_TOKEN"
```

## Environment

Credentials are automatically loaded from 1Password via direnv:
- **K3S_TOKEN**: Token for cluster authentication
- **KUBECONFIG**: Merged config with both clusters
- **DOCKER_HOST**: Points to tower's Docker daemon

Just `cd` into this directory and direnv handles the rest!
