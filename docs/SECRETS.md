# Secret Management Guide

This document describes how to manage secrets for the Enchanted Castle project using 1Password.

## Overview

All sensitive credentials and API keys should be stored in 1Password, not in the repository. Template files (`.env.example`) are provided as guides.

## 1Password Structure

Create a vault named "Enchanted Castle" with the following structure:

### Dify Configuration

Create a "Dify Configuration" login item with:

- **Title:** Dify Configuration
- **Username:** admin
- **Email:** steve@rude.la
- **Password:** (use a secure generated password)
- **Custom fields:**
  - `DIFY_SECRET_KEY`: Application secret key (use a secure generated value like `sk-...`)
  - `DIFY_SANDBOX_API_KEY`: Sandbox API key
  - `POSTGRES_PASSWORD`: PostgreSQL database password
  - `REDIS_PASSWORD`: Redis password
  - `WEAVIATE_API_KEY`: Weaviate API key for vector store
  - `WEAVIATE_USER_EMAIL`: User email for Weaviate admin access
  - `ADMIN_EMAIL`: Admin email for Dify
  - `DIFY_APP_WEB_URL`: Application web URL
  - `DIFY_CONSOLE_WEB_URL`: Console web URL
  - `PLUGIN_DAEMON_KEY`: Plugin daemon API key
  - `S3_ACCESS_KEY`: (if using S3)
  - `S3_SECRET_KEY`: (if using S3)
  - `S3_ENDPOINT`: (if using S3)
  - `ALIYUN_ACCESS_KEY`: (if using Aliyun OSS)
  - `ALIYUN_SECRET_KEY`: (if using Aliyun OSS)
  - `ALIYUN_BUCKET_NAME`: (if using Aliyun OSS)
  - `ALIYUN_OSS_PATH`: (if using Aliyun OSS)
  - `SENTRY_DSN`: (if using Sentry monitoring)

### K3s Configuration

Create a "K3s Configuration" login item with:

- **Title:** K3s Configuration
- **Username:** k3s
- **Password:** (use a secure generated password)
- **Custom fields:**
  - `K3S_TOKEN`: K3s cluster token for joining nodes

### Database Backup

Store database backups and export files separately:

- Create a "Dify Database Backup" secure note with dated backups
- Never commit `.sql` dump files to the repository

## Retrieving Secrets

### Using 1Password CLI

```bash
# Sign in to 1Password
eval "$(op signin)"

# Retrieve a specific secret
op read "op://Enchanted Castle/Dify Configuration/DIFY_SECRET_KEY"

# List all secrets in a vault
op item list --vault "Enchanted Castle"
```

### Setting Up Local .env Files

1. Create `.env` files by copying from `.env.example`:
   ```bash
   cp dify/.env.example dify/.env
   ```

2. Fill in values from 1Password using the CLI:
   ```bash
   # Example: Get secret and insert into file
   SECRET=$(op read "op://Enchanted Castle/Dify Configuration/DIFY_SECRET_KEY")
   sed -i "s/{{DIFY_SECRET_KEY}}/$SECRET/g" dify/.env
   ```

3. Or manually using the 1Password app to look up values and paste them in

## Security Practices

1. **Never commit `.env` files** - they are in `.gitignore`
2. **Never commit `kubeconfig.yaml` files** - they are in `.gitignore` and contain cluster credentials
3. **Never commit database backups** - they are in `.gitignore`
4. **Never commit private keys** - they are in `.gitignore`
5. **Always use `.example` templates** - they have placeholders but no real values
6. **Rotate sensitive keys regularly** - update in 1Password and redeploy
7. **Keep 1Password session secure** - logout after work
8. **Set restrictive file permissions** - kubeconfig should be `600` (readable only by owner)

## Environment Variables Reference

See the `.env.example` files in each service directory for complete lists of configuration options.

- `dify/.env.example` - Dify service configuration
- `k3s/.env.example` - K3s cluster configuration
