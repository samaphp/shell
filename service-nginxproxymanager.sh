#/bin/sh
# Install NGINX Proxy Manager

# Install docker
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker

# mkdir -p /home/project/nginxproxy
# cd /home/project/nginxproxy
echo "version: '3.8'\nservices:\n  app:\n    image: 'jc21/nginx-proxy-manager:latest'\n    restart: unless-stopped\n    ports:\n      - '80:80'\n      - '81:81'\n      - '443:443'\n    volumes:\n      - ./data:/data\n      - ./letsencrypt:/etc/letsencrypt" > docker-compose.yml
docker compose -p nginxproxy up -d

# Default admin is working on port 81
# Email:    admin@example.com
# Password: changeme
