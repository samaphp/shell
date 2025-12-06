# Khoj Production Installation Guide for Local Network

This guide will help you install and configure Khoj for production use on your local network.

## Overview

Khoj is a personal AI assistant that can:
- Chat with local or online LLMs (GPT, Claude, Gemini, Llama, etc.)
- Search and answer questions from your documents
- Create custom AI agents
- Work completely offline with local models
- Stay private with self-hosting

## Prerequisites

### System Requirements
- **Minimum**: 8 GB RAM, 5 GB disk space
- **Recommended**: 16 GB RAM (especially for local AI models)
- **GPU** (optional but recommended): NVIDIA, AMD, or Mac M1+ for faster responses
- **OS**: Linux, macOS, or Windows with WSL2

### Software Requirements
- Docker and Docker Compose

---

## Installation Method 1: Docker (Recommended for Production)

Docker is the easiest and most reliable way to deploy Khoj in production.

### Step 1: Install Docker on Ubuntu 24.04 LTS

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get update
sudo apt-get install -y docker-compose-plugin

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Step 2: Download and Configure (Production Setup in /opt)

For a production Ubuntu server, it's recommended to install in `/opt/khoj`:

```bash
# Create Khoj directory in /opt (production standard location)
sudo mkdir -p /opt/khoj
sudo chown $USER:$USER /opt/khoj
cd /opt/khoj

# Download docker-compose.yml
wget https://raw.githubusercontent.com/khoj-ai/khoj/master/docker-compose.yml

# OR use curl if wget is not available
# curl -O https://raw.githubusercontent.com/khoj-ai/khoj/master/docker-compose.yml

# Create data directory for persistent storage
mkdir -p /opt/khoj/data
```

### Step 3: Configure Environment Variables

Edit the `docker-compose.yml` file:

```bash
nano docker-compose.yml  # or use your preferred editor
```

**Critical settings to configure:**

```yaml
environment:
  # REQUIRED: Set secure admin credentials
  - KHOJ_ADMIN_EMAIL=admin@yourdomain.com
  - KHOJ_ADMIN_PASSWORD=your_secure_password_here
  - KHOJ_DJANGO_SECRET_KEY=your_secret_key_here_make_it_long_and_random

  # For local network access (replace with your server's IP)
  - KHOJ_DOMAIN=192.168.1.100  # Your server's local IP
  - KHOJ_NO_HTTPS=True  # Set to True for HTTP on local network
  # Optional: API Keys for commercial models
  #- OPENAI_API_KEY=your_openai_key_here
  #- ANTHROPIC_API_KEY=your_anthropic_key_here
  #- GEMINI_API_KEY=your_gemini_key_here
  # Using local LLM
  - OPENAI_API_KEY=sk-123
  - OPENAI_BASE_URL=https://yourlocalllm.localhost/api/v1/
  - KHOJ_DEFAULT_CHAT_MODEL=gpu/ALLaM
  # Better to disable LLM download and relay to external LLM (outside this server)
  - KHOJ_DISABLE_LLM_DOWNLOAD=True
  - KHOJ_DISABLE_EMBEDDING_DOWNLOAD=True
  # Optional: For using Ollama or other local models
  # - OPENAI_BASE_URL=http://host.docker.internal:11434/v1
```

**For network access, also update the ports section:**

You may not need this, but just in case you was not able to reach this service:

```yaml
ports:
  - "0.0.0.0:42110:42110"  # Allows access from all network interfaces
```

### Step 4: Start Khoj

```bash
cd /opt/khoj
docker compose up -d

# Check logs to ensure it started successfully
docker compose logs -f

# To stop watching logs, press Ctrl+C
```

Wait until you see: **`🌖 Khoj is ready to engage`**

**Useful Docker Commands:**
```bash
# Stop Khoj
docker compose down

# Restart Khoj
docker compose restart

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### Step 5: Initial Setup

1. **Access Khoj Web Interface:**
   - From the server: `http://localhost:42110`
   - From other devices: `http://YOUR_SERVER_IP:42110`

2. **Login to Admin Panel:**
   - Go to: `http://YOUR_SERVER_IP:42110/server/admin`
   - Use the admin credentials you set in docker-compose.yml
   - ⚠️ Use `localhost` (not 127.0.0.1) if accessing from the server to avoid CSRF errors

3. **Configure Chat Models:**
   - Navigate to "AI Model Api" section
   - Add your preferred AI provider (OpenAI, Anthropic, Gemini, or local)
   - Create chat models pointing to your configured APIs

---

## Post-Installation Configuration

### 1. Configure Chat Models

1. Access admin panel: `http://YOUR_SERVER_IP:42110/server/admin`
2. Go to "AI Model Api" → "Add AI Model API"
3. Configure your preferred provider:

**For OpenAI:**
- Name: OpenAI
- API Key: Your OpenAI API key
- API Base URL: (leave empty unless using proxy)

**For Local Models (Ollama):**
- Name: Ollama
- API Key: (leave empty)
- API Base URL: `http://localhost:11434/v1`

4. Go to "Chat Model" → "Add Chat Model"
5. Configure model settings:
   - Chat Model: e.g., `gpt-4o`, `claude-3-5-sonnet-20240620`, or `llama3`
   - Model Type: Select appropriate type
   - AI Model API: Select the API you configured

### 2. Setup Document Sync

**Option A: Upload files directly**
- Drag and drop files at `http://YOUR_SERVER_IP:42110`

**Option B: Desktop Client**
- Download from the [Khoj website](https://khoj.dev/downloads)
- Configure server URL in settings

**Option C: Obsidian Plugin**
- Install "Khoj" from Community Plugins
- Set server URL to `http://YOUR_SERVER_IP:42110`

### 3. Network Security Considerations

**Firewall Configuration:**
```bash
# Allow Khoj port on firewall (Linux)
sudo ufw allow 42110/tcp
sudo ufw reload
```

**Reverse Proxy (Optional but Recommended):**

If you want HTTPS and better security, set up Nginx:

```nginx
server {
    listen 80;
    server_name khoj.yourdomain.local;
    
    location / {
        proxy_pass http://localhost:42110;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Maintenance and Upgrades

### Backup Your Data

**Docker (from /opt/khoj):**
```bash
# Stop Khoj
cd /opt/khoj
docker compose down

# Backup entire khoj directory
sudo tar -czf /backup/khoj-backup-$(date +%Y%m%d).tar.gz /opt/khoj

# Or backup only data
sudo tar -czf /backup/khoj-data-backup-$(date +%Y%m%d).tar.gz /opt/khoj/data

# Restart Khoj
docker compose up -d
```

**Create automatic backup script:**
```bash
sudo nano /usr/local/bin/backup-khoj.sh
```

Add this content:
```bash
#!/bin/bash
BACKUP_DIR="/backup/khoj"
mkdir -p $BACKUP_DIR
cd /opt/khoj
docker compose down
tar -czf $BACKUP_DIR/khoj-backup-$(date +%Y%m%d-%H%M%S).tar.gz /opt/khoj
docker compose up -d
# Keep only last 7 backups
find $BACKUP_DIR -name "khoj-backup-*.tar.gz" -mtime +7 -delete
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/backup-khoj.sh
```

Add to crontab for weekly backups:
```bash
sudo crontab -e
# Add this line for weekly backup every Sunday at 2 AM
0 2 * * 0 /usr/local/bin/backup-khoj.sh
```

### Upgrade Khoj

**Docker:**
```bash
cd /opt/khoj
docker compose down
docker compose pull
docker compose up -d

# Check logs to verify upgrade
docker compose logs -f
```

---

## Troubleshooting

### Port Already in Use
```bash
# Check what's using port 42110
sudo lsof -i :42110
# Kill the process or change Khoj port in docker-compose.yml
```

### Can't Access from Network
- Check firewall settings
- Verify KHOJ_DOMAIN is set to server IP
- Ensure docker-compose.yml binds to `0.0.0.0:42110`

### CSRF Error in Admin Panel
- Use `localhost` instead of `127.0.0.1` when accessing from server
- Set `KHOJ_ALLOWED_DOMAIN` environment variable

### Memory Issues
- Increase Docker memory in Docker Desktop settings
- For pip install, ensure system has enough RAM
- Consider using smaller local models

### Database Connection Issues
```bash
# Docker: Reset database
docker-compose down -v
docker-compose up -d
```

---

## Testing Your Installation

1. **Test web interface:** Visit `http://YOUR_SERVER_IP:42110`
2. **Test chat:** Send a message in the chat interface
3. **Test document search:** Upload a document and ask questions about it
4. **Test from another device:** Access from a different device on your network
5. **Check logs:** Look for any errors in logs

```bash
# Docker logs
docker-compose logs -f

# Pip logs
# Check terminal output where khoj is running
```

---

## Support and Resources

- **Documentation:** https://docs.khoj.dev
- **GitHub:** https://github.com/khoj-ai/khoj
- **Discord:** https://discord.gg/BDgyabRM6e
- **Website:** https://khoj.dev

---

## Security Best Practices for Production

1. ✅ Use strong admin passwords
2. ✅ Set up firewall rules
3. ✅ Regular backups
4. ✅ Keep Khoj updated
5. ✅ Use HTTPS with reverse proxy for public access
6. ✅ Limit network access to trusted devices
7. ✅ Monitor logs regularly
8. ✅ Don't expose to public internet without proper security

Your Khoj installation is now ready for production use on your local network! 🚀
