#!/bin/bash
# Author: Saud bin Mohammed
# Connect to GlobalProtect using openconnect command

_userName=''
_gatewayIp=''
_serverCert=''

echo 'Remember if you want to disconnect, it is good to disconnect your network and connect it again'
echo 'Please hit Enter to write your password'

# Connect to VPN
sudo openconnect --protocol=gp -u $_userName --cookie-on-stdin $_gatewayIp --servercert $_serverCert

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
