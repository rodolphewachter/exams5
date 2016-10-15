#!/bin/bash

chemin="/opt/vpn/x509"
openvpn="/etc/openvpn"
chemincle="/etc/openvpn/easy-rsa"

echo "1-Ajouter un serveur"
echo "2-Ajouter un client"
echo "3-Activer un serveur"
echo "4-Supprimer un serveur"
echo "5-Supprimer un client"
echo "6-Désactiver un serveur"
echo "7-Activer client-to-client"
echo "8-Désactiver client-to-client"
read reponse

#CREATION DU SERVEUR
if [ $reponse -eq "1" ];then
	echo "Nom du serveur :"
	read server

	cd $chemincle
	source vars
	#On efface les éventuelles clés :
	./clean-all
	#On crée le ca
	./build-ca
	#On crée le certificat et la clé pour le serveur :
	./build-key-server $server
	#On crée diffie-Hellman
	./build-dh

	#On crée le répertoire du serveur :
	mkdir -p $chemin/serveur/$server

	#tls-auth
	openvpn --genkey --secret $chemincle/keys/tls.key

	#On envoie les certificats dans le dossier serveur :
	cp $chemincle/keys/ca.crt $chemin/serveur/$server
	cp $chemincle/keys/$server.* $chemin/serveur/$server
	cp $chemincle/keys/dh2048.* $chemin/serveur/$server
	cp $chemincle/keys/tls.key $chemin/serveur/$server

	echo "Création du fichier de configuration serveur !"
echo "
#Configuration serveur

mode server 
proto udp
port 1194
dev tun1

ca ca.crt
cert $server.crt
key $server.key
dh dh2048.pem
tls-auth tls.key 0
cipher AES-256-CBC

client-to-client
server 10.8.2.0 255.255.255.0
push 'redirect-gateway def1'
push 'dhcp-option DNS 8.8.8.8'
keepalive 10 120

user nobody 
group nogroup 
persist-key 
persist-tun 
comp-lzo " > $chemin/serveur/$server/$server.conf
	echo "Votre configuration serveur est achever !"
#FIN - CREATION SERVEUR
#----------------------------------

#CREATION CLIENT
elif [ $reponse -eq "2" ];then
	echo "Nom du client :"
        read client

	cd $chemincle
	source vars
	#On crée le certificat et la clé pour le serveur :
        ./build-key $client

	##On crée le répertoire du serveur :
        mkdir -p $chemin/client/$client

	#On envoie les certificats dans le client :
        cp $chemincle/keys/ca.crt $chemin/client/$client
        cp $chemincle/keys/$client.* $chemin/client/$client
	cp $chemincle/keys/tls.key $chemin/client/$client
	echo "Création du fichier de configuration client"
echo "
#Configuration client
client
dev tun1
proto udp
remote labo.itinet.fr
port 10011

resolv-retry infinite
nobind
persist-key
persist-tun
	
ca ca.crt
cert $client.crt
key $client.key
tls-auth tls.key 1
cipher AES-256-CBC

comp-lzo" > $chemin/client/$client/$client.conf
	echo "Votre configuration client est achever !"
#FIN - CREATION CLIENT
#--------------------------------

#ACTIVER UN SERVEUR
elif [ $reponse -eq "3" ];then
	echo "Liste des serveurs disponible :"
	ls $chemin/serveur/
	echo "Nom du serveur à activer :"
	read server

	ln -s $chemin/serveur/$server/* $openvpn/
	service openvpn restart
	echo "Serveur actif !"
#FIN - ACTIVER UN SERVEUR
#---------------------------------

#SUPPRIMER UN SERVEUR
elif [ $reponse -eq "4" ];then
	echo "Liste des serveurs disponible :"
        ls $chemin/serveur/
	echo "Nom du serveur à supprimer :"
        read server
	
	cd $chemincle
	source vars
	./clean-all
	rm $openvpn/ca.crt 
        rm $openvpn/$server.* 
        rm $openvpn/dh2048.* 
        rm $openvpn/tls.key 
	rm -R $chemin/serveur/$server
	
	service openvpn restart
	echo "Serveur supprimer !"
#FIN - SUPPRIMER UN SERVEUR
#-----------------------------------

#SUPPRIMER UN CLIENT
elif [ $reponse -eq "5" ];then
	echo "Liste des clients disponible :"
        ls $chemin/client/
        echo "Nom du client à supprimer :"
        read client
	
	rm $chemincle/$client.*
	rm -r $chemin/client/$client

#FIN - SUPPRIMER UN CLIENT
#-----------------------------------

#DESACTIVER UN SERVEUR
elif [ $reponse -eq "6" ];then
	echo "Liste des serveurs disponible :"
	ls $chemin/serveur/
	echo "Nom du serveur à désactiver :"
	read server

	rm $openvpn/ca.crt
        rm $openvpn/$server.*
        rm $openvpn/dh2048.*
        rm $openvpn/tls.key

	service openvpn restart
	echo "Serveur désactiver !"

#FIN - DESACTIVER UN SERVEUR
#------------------------------------

#ACTIVER CLIENT-TO-CLIENT
elif [ $reponse -eq "7" ];then
	echo "Liste des serveurs disponible :"
        ls $chemin/serveur/
        echo "Nom du serveur à désactiver :"
        read server
	
	sed -i 's/;client-to-client/client-to-client/g' $chemin/serveur/$server/$server.conf
	service openvpn restart
	echo "Client-to-client activer"
#FIN - ACTIVER CLIENT-TO-CLIENT"
#------------------------------------

#DESACTIVER CLIENT-TO-CLIENT
elif [ $reponse -eq "8" ];then
	echo "Liste des serveurs disponible :"
        ls $chemin/serveur/
        echo "Nom du serveur à désactiver :"
        read server
	
	sed -i 's/client-to-client/;client-to-client/g' $chemin/serveur/$server/$server.conf	
	service openvpn restart
	echo "Client-to-client désactiver"
#FIN - DESACTIVER CLIENT-TO-CLIENT
fi
	
