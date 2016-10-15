#!/bin/bash

echo "Que souhaitez vous faire ? : "
echo "1-Création et suppression PKI"
echo "2-Création et suppression de règle FIREWALL"
echo "3-Création et suppression VPN"
read reponse

if [ $reponse = "1" ];then
	sudo bash /opt/rootpki/pki.sh
elif [ $reponse = "2" ];then
	sudo bash /opt/firewall/firewallScript.sh
elif [ $reponse = "3" ];then
	sudo bash /opt/vpn/x509/x509.sh
fi

