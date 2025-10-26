# Multi-Cluster K3s Setup

This setup creates two independent k3s clusters with their own control planes:
- **tower**: k3s server running in Docker on Unraid
- **karuna**: k3s server running natively on this Ubuntu machine

## Quick Setup

### 1. Install k3s on karuna
```bash
chmod +x install-karuna.sh
./install-karuna.sh
```

### 2. Start tower cluster
First, fix Docker connectivity to tower. Update `.env`:
```bash
# Use tower's IP address if hostname resolution fails
DOCKER_HOST=tcp://192.168.4.47:2375
```

Then start:
```bash
./start.sh
```

### 3. Merge kubeconfigs
```bash
chmod +x merge-kubeconfigs.sh
./merge-kubeconfigs.sh
```

This creates `kubeconfig/merged-kubeconfig.yaml` with both clusters.

### 4. Store in 1Password

```bash
# Store the K3S_TOKEN
op item create --category=password --title="K3s Token" \
  --vault=Personal K3S_TOKEN=$(cat .env | grep K3S_TOKEN | cut -d= -f2)

# Store the merged kubeconfig
op document create kubeconfig/merged-kubeconfig.yaml \
  --title="k3s-merged-kubeconfig" \
  --vault=Personal
```

### 5. Update direnv
```bash
cp .envrc.new .envrc
direnv allow
```

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

### Deploy to specific cluster using labels
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

### View resources across both clusters
```bash
# Tower
kubectl --context=tower get pods -A

# Karuna
kubectl --context=karuna get pods -A

# Or switch context
kubectl config use-context tower
kubectl get pods -A
```

## Architecture

- Each cluster has its own control plane (API server, scheduler, controller)
- Clusters are completely independent
- Use `kubectl config use-context` to switch between them
- Use node selectors with `hostname` or `cluster` labels to target specific machines
- Credentials stored securely in 1Password and loaded via direnv

## Troubleshooting

### Tower cluster not accessible
Check Docker connectivity:
```bash
DOCKER_HOST=tcp://192.168.4.47:2375 docker ps
```

If it fails, verify:
1. Docker daemon is exposed on tower (Unraid Docker settings)
2. Port 2375 is accessible
3. Use IP instead of hostname if DNS resolution fails

### Can't access karuna cluster
Check k3s service:
```bash
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

### 1Password integration not working
Ensure:
1. 1Password CLI is installed and authenticated: `op account list`
2. Items exist in 1Password with correct names
3. direnv is installed and allowed: `direnv allow`
