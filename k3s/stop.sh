#!/bin/bash

echo "Stopping k3s cluster..."
docker compose down
echo "✓ k3s cluster stopped"
