#!/bin/bash

# Dify Configuration Recreation Script
# This script recreates docker-compose.yaml and .env files from running containers

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="dify_config_backup_${TIMESTAMP}"

echo "🔧 Dify Configuration Recreation Script"
echo "========================================"
echo "Timestamp: $(date)"
echo "Backup directory: ${BACKUP_DIR}"
echo ""

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Function to extract environment variables from a container
extract_env_vars() {
    local container_name=$1
    local output_file=$2
    
    echo "📋 Extracting environment variables from ${container_name}..."
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        docker inspect "${container_name}" --format='{{range .Config.Env}}{{println .}}{{end}}' > "${output_file}"
        echo "   ✅ Extracted $(wc -l < "${output_file}") variables"
    else
        echo "   ⚠️  Container ${container_name} not found"
        touch "${output_file}"
    fi
}

# Function to get container configuration
get_container_config() {
    local container_name=$1
    echo "🔍 Getting configuration for ${container_name}..."
    
    if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        docker inspect "${container_name}" > "${BACKUP_DIR}/${container_name}_config.json"
        echo "   ✅ Configuration saved"
    else
        echo "   ⚠️  Container ${container_name} not found"
    fi
}

echo "🗂️  Extracting container configurations..."
# Extract configurations from all containers
get_container_config "docker-api-1"
get_container_config "docker-web-1"
get_container_config "docker-worker-1"
get_container_config "docker-db-1"
get_container_config "docker-redis-1"
get_container_config "docker-nginx-1"
get_container_config "docker-weaviate-1"
get_container_config "docker-sandbox-1"
get_container_config "docker-ssrf_proxy-1"
get_container_config "docker-plugin_daemon-1"

echo ""
echo "📋 Extracting environment variables..."
# Extract environment variables
extract_env_vars "docker-api-1" "${BACKUP_DIR}/api_env.txt"
extract_env_vars "docker-worker-1" "${BACKUP_DIR}/worker_env.txt"
extract_env_vars "docker-web-1" "${BACKUP_DIR}/web_env.txt"
extract_env_vars "docker-db-1" "${BACKUP_DIR}/db_env.txt"
extract_env_vars "docker-redis-1" "${BACKUP_DIR}/redis_env.txt"

echo ""
echo "📝 Creating .env file..."

# Create .env file
cat > .env << 'EOF'
# Dify Environment Configuration
# Generated automatically from running containers
# Timestamp: TIMESTAMP_PLACEHOLDER

# ===== CORE APPLICATION SETTINGS =====
EOF

# Add timestamp
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date)/" .env

# Extract and format key environment variables
echo "# Core Application" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(SECRET_KEY|DEPLOY_ENV|EDITION|LOG_LEVEL)=" "${BACKUP_DIR}/api_env.txt" | head -10 >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# API URLs and CORS" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(CONSOLE_API_URL|CONSOLE_WEB_URL|SERVICE_API_URL|APP_API_URL|APP_WEB_URL)=" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
    grep -E "^(CONSOLE_CORS_ALLOW_ORIGINS|WEB_API_CORS_ALLOW_ORIGINS)=" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== DATABASE SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(DB_|DATABASE_|POSTGRES_)" "${BACKUP_DIR}/api_env.txt" | grep -v "DATABASE_URL" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== REDIS SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^REDIS_" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== VECTOR STORE SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(VECTOR_STORE|WEAVIATE_)" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== STORAGE SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(STORAGE_|S3_|AZURE_|ALIYUN_)" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== CELERY SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^CELERY_" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== MAIL SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(MAIL_|SMTP_)" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

echo "" >> .env
echo "# ===== OTHER SETTINGS =====" >> .env
if [ -f "${BACKUP_DIR}/api_env.txt" ]; then
    grep -E "^(SENTRY_|CODE_|UPLOAD_|ETL_|CHECK_)" "${BACKUP_DIR}/api_env.txt" >> .env 2>/dev/null || true
fi

# Remove duplicates and clean up
sort .env | uniq > .env.tmp && mv .env.tmp .env

echo "   ✅ .env file created"

echo ""
echo "🐳 Creating docker-compose.yaml file..."

# Create docker-compose.yaml
cat > docker-compose.yaml << 'EOF'
version: '3'
services:
  # API service
  api:
    image: langgenius/dify-api:1.4.1
    restart: always
    environment:
      - MODE=api
    depends_on:
      - db
      - redis
    volumes:
      - ./volumes/app/storage:/app/api/storage
    networks:
      - ssrf_proxy_network
      - default

  # Background worker
  worker:
    image: langgenius/dify-api:1.4.1
    restart: always
    environment:
      - MODE=worker
    depends_on:
      - db
      - redis
    volumes:
      - ./volumes/app/storage:/app/api/storage
    networks:
      - ssrf_proxy_network
      - default

  # Frontend web application
  web:
    image: langgenius/dify-web:1.4.1
    restart: always
    environment:
      - EDITION=SELF_HOSTED
    networks:
      - ssrf_proxy_network
      - default

  # PostgreSQL database
  db:
    image: postgres:15-alpine
    restart: always
    environment:
      PGUSER: postgres
      POSTGRES_PASSWORD: difyai123456
      POSTGRES_DB: dify
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ./volumes/db/data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD', 'pg_isready']
      interval: 1s
      timeout: 3s
      retries: 30

  # Redis cache and session store
  redis:
    image: redis:6-alpine
    restart: always
    command: redis-server --requirepass difyai123456
    volumes:
      - ./volumes/redis/data:/data
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']

  # Weaviate vector database
  weaviate:
    image: semitechnologies/weaviate:1.19.0
    restart: always
    volumes:
      - ./volumes/weaviate:/var/lib/weaviate
    environment:
      - AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=false
      - DEFAULT_VECTORIZER_MODULE=none
      - CLUSTER_HOSTNAME=node1
      - AUTHENTICATION_APIKEY_ENABLED=true
      - AUTHENTICATION_APIKEY_ALLOWED_KEYS=WVF5YThaHlkYwhGUSmCRgsX3tD5ngdN8pkih
      - AUTHENTICATION_APIKEY_USERS=hello@dify.ai
      - AUTHORIZATION_ADMINLIST_ENABLED=true
      - AUTHORIZATION_ADMINLIST_USERS=hello@dify.ai

  # Sandbox service for code execution
  sandbox:
    image: langgenius/dify-sandbox:0.2.12
    restart: always
    environment:
      - API_KEY=dify-sandbox
      - GIN_MODE=release
      - WORKER_TIMEOUT=15
    volumes:
      - ./volumes/sandbox/dependencies:/dependencies
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:8194/health']

  # SSRF Proxy
  ssrf_proxy:
    image: ubuntu/squid:latest
    restart: always
    volumes:
      - ./volumes/ssrf_proxy/squid.conf:/etc/squid/squid.conf
    networks:
      - ssrf_proxy_network
      - default

  # Plugin daemon (if present)
  plugin_daemon:
    image: langgenius/dify-plugin-daemon:0.1.1-local
    restart: always
    volumes:
      - ./volumes/plugins:/app/plugins
    environment:
      - SECRET_KEY=${SECRET_KEY:-}
    ports:
      - "5003:5003"
    networks:
      - default

  # Nginx reverse proxy
  nginx:
    image: nginx:latest
    restart: always
    volumes:
      - ./volumes/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./volumes/nginx/proxy.conf:/etc/nginx/proxy.conf
      - ./volumes/nginx/conf.d:/etc/nginx/conf.d
    depends_on:
      - api
      - web
    ports:
      - "80:80"
      - "443:443"

networks:
  ssrf_proxy_network:
    driver: bridge
    internal: true

volumes:
  db:
    driver: local
  redis:
    driver: local
  weaviate:
    driver: local
EOF

# Extract actual passwords and keys from containers
if [ -f "${BACKUP_DIR}/db_env.txt" ]; then
    DB_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "${BACKUP_DIR}/db_env.txt" | cut -d'=' -f2 | head -1)
    if [ ! -z "$DB_PASSWORD" ]; then
        sed -i "s/POSTGRES_PASSWORD: difyai123456/POSTGRES_PASSWORD: $DB_PASSWORD/" docker-compose.yaml
    fi
fi

if [ -f "${BACKUP_DIR}/redis_env.txt" ]; then
    REDIS_PASSWORD=$(grep "^REDIS_PASSWORD=" "${BACKUP_DIR}/api_env.txt" | cut -d'=' -f2 | head -1)
    if [ ! -z "$REDIS_PASSWORD" ] && [ "$REDIS_PASSWORD" != "" ]; then
        sed -i "s/redis-server --requirepass difyai123456/redis-server --requirepass $REDIS_PASSWORD/" docker-compose.yaml
    else
        sed -i "s/redis-server --requirepass difyai123456/redis-server/" docker-compose.yaml
    fi
fi

echo "   ✅ docker-compose.yaml file created"

# Create volume directories
echo ""
echo "📁 Creating volume directories..."
mkdir -p volumes/{app/storage,db/data,redis/data,weaviate,sandbox/dependencies,ssrf_proxy,nginx/conf.d,plugins}
echo "   ✅ Volume directories created"

# Create basic nginx configuration
echo ""
echo "🌐 Creating nginx configuration..."
cat > volumes/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 15M;
    
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > volumes/nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location /console/api {
        proxy_pass http://api:5001;
        include proxy.conf;
    }

    location /api {
        proxy_pass http://api:5001;
        include proxy.conf;
    }

    location /v1 {
        proxy_pass http://api:5001;
        include proxy.conf;
    }

    location /files {
        proxy_pass http://api:5001;
        include proxy.conf;
    }

    location / {
        proxy_pass http://web:3000;
        include proxy.conf;
    }
}
EOF

cat > volumes/nginx/proxy.conf << 'EOF'
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_redirect off;
proxy_buffering off;
proxy_request_buffering off;
EOF

# Create basic squid configuration
cat > volumes/ssrf_proxy/squid.conf << 'EOF'
http_port 3128
coredump_dir /var/spool/squid
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
http_access allow all
EOF

echo "   ✅ Nginx and Squid configurations created"

# Create upgrade script
echo ""
echo "🚀 Creating upgrade script for Dify 1.5.0..."
cat > upgrade_to_1.5.0.sh << 'EOF'
#!/bin/bash

echo "🚀 Upgrading Dify to 1.5.0..."

# Backup current setup
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
cp docker-compose.yaml "docker-compose.yaml.backup.${BACKUP_TIME}"
cp .env ".env.backup.${BACKUP_TIME}"

echo "📦 Backing up database..."
docker exec docker-db-1 pg_dump -U postgres dify > "dify_backup_${BACKUP_TIME}.sql"

echo "🛑 Stopping services..."
docker-compose down

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
docker-compose pull

echo "🚀 Starting services..."
docker-compose up -d

echo "⏳ Waiting for services to start..."
sleep 30

echo "🔍 Checking service status..."
docker-compose ps

echo "✅ Upgrade complete! Dify 1.5.0 should now be running."
echo "🌐 Access your Dify instance at: http://localhost"
echo ""
echo "New features in 1.5.0:"
echo "- Enhanced workflow debugging with persistent variables"
echo "- Drag-and-drop DSL functionality"
echo "- Improved UI components"
echo "- Better dashboard integration"
EOF

chmod +x upgrade_to_1.5.0.sh

echo "   ✅ Upgrade script created"

# Summary
echo ""
echo "🎉 Configuration Recreation Complete!"
echo "======================================"
echo ""
echo "📁 Files created:"
echo "   ├── .env (environment variables)"
echo "   ├── docker-compose.yaml (service definitions)"
echo "   ├── volumes/ (data directories)"
echo "   ├── upgrade_to_1.5.0.sh (upgrade script)"
echo "   └── ${BACKUP_DIR}/ (extracted configurations)"
echo ""
echo "🚀 Next steps:"
echo "   1. Review the generated .env file and update any missing values"
echo "   2. Test the configuration: docker-compose config"
echo "   3. Run the upgrade: ./upgrade_to_1.5.0.sh"
echo ""
echo "⚠️  Important notes:"
echo "   - Check database and Redis passwords in .env file"
echo "   - Verify API URLs and CORS settings"
echo "   - Review storage and vector store configurations"
echo "   - Test the setup before running the upgrade"
echo ""
echo "💾 Backup location: ${BACKUP_DIR}/"
echo "📝 Configuration extracted from running containers"
echo ""
echo "Happy upgrading! 🎊"
