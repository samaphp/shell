#/bin/sh
# Install Prometheus and Grafana with NodeExporter for current machine

git clone https://github.com/stefanprodan/dockprom
cd dockprom
ADMIN_USER=admin ADMIN_PASSWORD=admin ADMIN_PASSWORD_HASH=JDJhJDE0JE91S1FrN0Z0VEsyWmhrQVpON1VzdHVLSDkyWHdsN0xNbEZYdnNIZm1pb2d1blg4Y09mL0ZP docker-compose up -d
