#!/bin/bash
# Author: Saud bin Mohammed
# Script to install protainer

docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:2.11.1

# now go to https://localhost:9443/
echo 'Please go to https://localhost:9443/ to finish the installation steps'
