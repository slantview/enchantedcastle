#!/bin/bash

set -e

# Generate secure token using openssl
K3S_TOKEN=$(openssl rand -base64 32)

# Update .env with the token
cat >> .env << EOF

# K3s security token (generated $(date))
K3S_TOKEN=$K3S_TOKEN
EOF

echo "✓ Generated K3S_TOKEN and saved to .env"
echo "  Token: $K3S_TOKEN"
