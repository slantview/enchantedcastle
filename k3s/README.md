# K3s on Docker

Single-host Kubernetes cluster running in Docker on your Unraid server.

## Prerequisites

- Docker CLI installed locally
- `kubectl` installed locally
- `docker-compose` available

## Quick Start

```bash
# Make the start script executable
chmod +x start.sh

# Start the k3s cluster
./start.sh

# Set your kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml

# Verify the cluster
kubectl cluster-info
kubectl get nodes
```

## Configuration

Edit `.env` to change:
- `DOCKER_HOST`: Point to your Unraid Docker daemon (default: tower.local:2375)
- `COMPOSE_PROJECT_NAME`: k3s project name

Edit `docker-compose.yml` to:
- Change k3s version: modify `rancher/k3s:latest` tag
- Add environment variables for k3s configuration
- Expose additional ports as needed

## Common Commands

```bash
# View cluster status
docker compose ps
docker compose logs k3s-server

# Stop the cluster
docker compose down

# Stop and remove volumes (clean slate)
docker compose down -v

# Deploy a test app
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer

# Access kubectl
kubectl get nodes
kubectl get pods --all-namespaces
```

## Kubeconfig

The kubeconfig is automatically generated and stored in `kubeconfig/kubeconfig.yaml`. 

To use it:
```bash
export KUBECONFIG=$(pwd)/kubeconfig/kubeconfig.yaml
```

Or copy it to your default kubectl location:
```bash
mkdir -p ~/.kube
cp kubeconfig/kubeconfig.yaml ~/.kube/config
```

## Troubleshooting

**Container won't start**
```bash
docker compose logs k3s-server
```

**kubeconfig not generating**
- Check that the `kubeconfig` directory exists or will be created
- Wait longer (up to 60s) for k3s to fully initialize
- Check Docker logs: `docker compose logs k3s-server`

**Can't connect to Docker daemon**
- Verify DOCKER_HOST is set correctly in `.env`
- Test connection: `docker ps`

**Ports already in use**
- Change port mappings in `docker-compose.yml` if 6443, 80, or 443 are in use
- Example: `"6443:6443"` becomes `"6444:6443"`
