#!/bin/bash
# Install langflow on a proxmox CT running ubuntu24.04 LTS using uv

apt update
apt upgrade
apt install -y software-properties-common
add-apt-repository ppa:deadsnakes/ppa
apt update
apt install -y python3.10 python3.10-venv python3.10-dev

# install pip
python3.10 -m ensurepip --upgrade
python3.10 -m pip install --upgrade pip
python3.10 -m pip install uv

# Langflow install steps
python3.10 -m venv langflow_venv
source langflow_venv/bin/activate
uv pip install langflow
uv run langflow run

# if you want to reinstall or upgrade later
#uv pip install langflow --force-reinstall
#uv pip install langflow -U


# Second option
#mkdir -p ./config
#chown -R 1000:1000 ./config
#chmod 700 ./config
#docker compose -p langflow up -d
# Test port
#nc -vz YOUR_LANGFLOW_IP 7860

# Suggested docker-compose file
#```
# version: "3.9"

# services:
#   langflow:
#     image: langflowai/langflow:latest
#     restart: unless-stopped
#     depends_on:
#       postgres:
#         condition: service_healthy
#     environment:
#       LANGFLOW_PORT: "7860"
#       LANGFLOW_HOST: "0.0.0.0"
#       LANGFLOW_DATABASE_URL: "postgresql://langflow:langflow@postgres:5432/langflow"
#       LANGFLOW_CONFIG_DIR: "/app/langflow"
#       LANGFLOW_SUPERUSER: "admin"
#       LANGFLOW_SUPERUSER_PASSWORD: "change_me"
#       LANGFLOW_LOG_LEVEL: "info"
#       LANGFLOW_WORKERS: "2"
#       LANGFLOW_OPEN_BROWSER: "False"
#     ports:
#       - "7860:7860"
#     volumes:
#       # Use a named volume (your original name) instead of ./config bind mount
# #      - langflow-data:/app/langflow:rw
#       - ./config:/app/langflow:rw
#     healthcheck:
#       test: ["CMD-SHELL", "curl -fsS http://localhost:7860/health || exit 1"]
#       interval: 15s
#       timeout: 5s
#       retries: 12

#   postgres:
#     image: postgres:16
#     restart: unless-stopped
#     environment:
#       POSTGRES_USER: "langflow"
#       POSTGRES_PASSWORD: "langflow"
#       POSTGRES_DB: "langflow"
#     volumes:
#       - langflow-postgres:/var/lib/postgresql/data
#     healthcheck:
#       test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
#       interval: 10s
#       timeout: 5s
#       retries: 15

#   qdrant:
#     image: qdrant/qdrant:latest
#     restart: unless-stopped
#     ports:
#       - "6333:6333"
#     volumes:
#       - qdrantdata:/qdrant/storage
#     healthcheck:
#       test: ["CMD-SHELL", "wget -qO- http://localhost:6333/readyz || exit 1"]
#       interval: 15s
#       timeout: 5s
#       retries: 12

# volumes:
#   langflow-postgres:
#   langflow-data:
#   qdrantdata:
#```
