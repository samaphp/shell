#!/bin/bash
# Author: Saud bin Mohammed
# Connect to GlobalProtect using openconnect command
# wget https://raw.githubusercontent.com/samaphp/shell/main/vpn-global-protect-openconnect.sh

_userName='YOUR_USERNAME'
_gatewayIp='GATEWAY_IP'
_serverCert='pin-sha256:HERE_PLEASE'
# If you don't know the _serverCert, consider removing it from the openconnect command below.

echo 'Do you want to route all traffic? (y/n)'
echo '(y): All your network traffic will go through the VPN automatically'
echo '(n): You will be connected, but nothing will go through the VPN. YOU NEED TO ROUTE IPs MANUALLY.'
read _route_all

echo 'Please hit Enter to write your password'

# Connect to VPN
sudo openconnect --protocol=gp -u $_userName --cookie-on-stdin $_gatewayIp --servercert $_serverCert --background

if [[ "$_route_all" == 'y' ]] ;
  then

    _directIp=$(curl ifconfig.me)
    _interfaceIp=$(curl ifconfig.me --interface tun0)
    if [[ "$_interfaceIp" == "$_gatewayIp" ]] ;
      then
      echo 'Perfect, we are connected.'
      sudo ip route add default dev tun0
      else
      echo 'Sorry! Something went wrong'
      echo 'directIp:'
      echo $_directIp
      echo 'interfaceIp:'
      echo $_interfaceIp
    fi

  else

    echo 'No default route.'
    # It is good to add your manual ip route command here

fi

echo 'Remember if you want to disconnect, it is good to disconnect your network and connect it again'
