#!/bin/bash

echo "🚀 Upgrading Dify to 1.5.0..."

# Backup current setup
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
cp docker-compose.yaml "docker-compose.yaml.backup.${BACKUP_TIME}"
cp .env ".env.backup.${BACKUP_TIME}"

echo "📦 Backing up database..."
docker exec docker-db-1 pg_dump -U postgres dify > "dify_backup_${BACKUP_TIME}.sql"

echo "🛑 Stopping services..."
docker compose down

echo "📝 Updating image versions..."
sed -i 's/langgenius\/dify-api:1\.4\.1/langgenius\/dify-api:1.5.0/g' docker-compose.yaml
sed -i 's/langgenius\/dify-web:1\.4\.1/langgenius\/dify-web:1.5.0/g' docker-compose.yaml
sed -i 's/langgenius\/dify-sandbox:0\.2\.12/langgenius\/dify-sandbox:0.2.13/g' docker-compose.yaml
sed -i 's/langgenius\/dify-plugin-daemon:0\.1\.1-local/langgenius\/dify-plugin-daemon:0.1.2-local/g' docker-compose.yaml

echo "📋 Adding new environment variables..."
if ! grep -q "PLUGIN_S3_USE_AWS" .env; then
    echo "PLUGIN_S3_USE_AWS=false" >> .env
fi
if ! grep -q "RESPECT_XFORWARD_HEADERS_ENABLED" .env; then
    echo "RESPECT_XFORWARD_HEADERS_ENABLED=true" >> .env
fi

echo "📥 Pulling new images..."
docker compose pull

echo "🚀 Starting services..."
docker compose up -d

echo "⏳ Waiting for services to start..."
sleep 30

echo "🔍 Checking service status..."
docker compose ps

echo "✅ Upgrade complete! Dify 1.5.0 should now be running."
echo "🌐 Access your Dify instance at: http://localhost"
echo ""
echo "New features in 1.5.0:"
echo "- Enhanced workflow debugging with persistent variables"
echo "- Drag-and-drop DSL functionality"
echo "- Improved UI components"
echo "- Better dashboard integration"
