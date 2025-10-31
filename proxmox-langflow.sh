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
