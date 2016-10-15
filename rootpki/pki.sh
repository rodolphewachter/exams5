#!/bin/bash

sudo echo "1 - Créer un certificat fille"
sudo echo "2 - Révoquer un certificat"
sudo echo "3 - Créer un certificat serveur"
sudo echo "4 - Créer un certificat client"
read reponse

chemin=/opt/rootpki
#CREATION DU CERTIFICAT FILLE

if [ $reponse = "1" ]; then
	nb_fille=$(awk '/^V/{x+=1}END{print x}' $chemin/ROOT_CBI/index.txt)
	limit=6
	if [ "$nb_fille" -lt "$limit" ];then

	sudo echo "Entrer le nom pour votre certificat fille"
	read nomFille
	sudo echo "Entrer votre common name"
	read cn
	sudo echo "Entrer votre nom"
	read nom
	sudo echo "Entrer votre département"
	read departement
	sudo echo "Entrer votre ville"
	read ville
	sudo echo "Entrer votre adresse email"
	read mail
	cd $chemin
	sudo mkdir -p $nomFille/newcerts
	sudo touch $nomFille/index.txt
	sudo echo '01' > $nomFille/serial
	sudo mkdir -p $nomFille/certificatCS 
	sudo touch ca.pass
	sudo echo "ericos" > ca.pass
	sudo touch $nomFille/openssl.cnf
	nomFilleMaj=`echo $nomFille | sed 's/.*/\U&/'`
	echo "[ ca ]
default_ca      = root_cbi

[ root_cbi ]
dir             = .
certs           = $chemin/ROOT_CBI/certs
new_certs_dir   = $chemin/ROOT_CBI/newcerts
database        = $chemin/ROOT_CBI/index.txt
certificate     = $chemin/ROOT_CBI/root_cbi.pem
serial          = $chemin/ROOT_CBI/serial
private_key     = $chemin/ROOT_CBI/root_cbi.key
default_days    = 365
default_md      = sha1
preserve        = no
policy          = policy_match

[ $nomFille ]
dir             = .
certs           = $chemin/$nomFille/certs
new_certs_dir   = $chemin/$nomFille/newcerts
database        = $chemin/$nomFille/index.txt
certificate     = $chemin/$nomFille/$nomFille.pem
serial          = $chemin/$nomFille/serial
private_key     = $chemin/$nomFille/$nomFille.key
default_days    = 365
default_md      = sha1
preserve        = no
policy          = policy_match

[ policy_match ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

[ req ]
distinguished_name      = req_distinguished_name

[ req_distinguished_name ]
countryName = Pays
countryName_default = FR
stateOrProvinceName = Departement
stateOrProvinceName_default = $departement
localityName = Ville
localityName_default = $ville
organizationName = organisation
organizationName_default = $nom
commonName = $cn
commonName_max = 64
emailAddress = $mail
emailAddress_max = 40

[ROOT_CBI]
nsComment                       = "CA Racine"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
basicConstraints                = critical,CA:TRUE,pathlen:1
keyUsage                        = keyCertSign, cRLSign

[$nomFilleMaj]
nsComment                       = "CA SSL"
basicConstraints                = critical,CA:TRUE,pathlen:0
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
issuerAltName                   = issuer:copy
keyUsage                        = keyCertSign, cRLSign
nsCertType                      = sslCA" >> $chemin/$nomFille/openssl.cnf
	
	sudo openssl genrsa -out $nomFille/$nomFille.key -des3 2048
	sudo openssl req -new -key $nomFille/$nomFille.key -out $nomFille/$nomFille.crs -config ./$nomFille/openssl.cnf -subj "/C=FR/ST=$departement/L=$ville/O=$nom/CN=$cn/emailAddress=$mail"
	sudo openssl ca -passin file:$chemin/ca.pass -out $nomFille/$nomFille.pem -config ./$nomFille/openssl.cnf -extensions ROOT_CBI -infiles $nomFille/$nomFille.crs
	sudo rm ca.pass
	else
		echo "Vous avez déjà 5 certificats fille"
	fi
#FIN - CREATION CERTIFICAT FILLE
#-----------------------------------------------------#
#REVOCATION CERTIFICAT FILLE

elif [ $reponse = "2" ]; then
	sudo echo "1 - un certificat fille"
	sudo echo "2 - un certificat serveur"
	sudo echo "3 - un certificat client"
	read reponse
	if [ $reponse = "1" ]; then
		sudo echo "Entrer le nom de votre common name"
		read cn
		sudo echo "Entrer le nom de votre certificat fille"
		read nomFille
		cd $chemin
		sudo touch ca.pass
		sudo echo "ericos" > ca.pass
		numero=`grep $cn ROOT_CBI/index.txt`
		numeroFinal=`echo $numero | cut -f 3 -d ' ' `
		sudo openssl ca -passin file:$chemin/ca.pass -revoke $chemin/ROOT_CBI/newcerts/$numeroFinal.pem -config $nomFille/openssl.cnf
		sudo rm ca.pass
		sudo mv  ./$nomFille ./archive
#FIN - REVOCATION CERTIFICAT FILLE
#------------------------------------------------------#
#REVOCATION CERTIFICAT SERVEUR
	elif [ $reponse = "2" ]; then
		sudo echo "Entrer le nom de votre certificat fille"
		read nomFille
		sudo echo "Entrer le nom de votre certificat serveur"
		read nomServeur
		cd $chemin
		nb_files=$(find ./$nomFille/newcerts/ -type f | wc -l)
		i=0
		while [ "$i" -lt "$nb_files" ]
		do
		let i++
		fichier=0$i.pem
		cmp -s ./$nomFille/certificatCS/$nomServeur.pem ./$nomFille/newcerts/$fichier
		
		if [ $? -eq 0 ]; then
			openssl ca -config ./$nomFille/openssl.cnf -name $nomFille -revoke ./$nomFille/newcerts/$fichier
			openssl ca -gencrl -config ./$nomFille/openssl.cnf -extensions $nomServeur -name $nomFille -crldays 1 -out ./$nomFille/crl.pem
			openssl crl -in ./$nomFille/crl.pem -text -noout
		fi
		let i--
		let i++
		done
		mv ./$nomFille/certificatCS/$nomServeur.crs ./archive
		mv ./$nomFille/certificatCS/$nomServeur.key ./archive
		mv ./$nomFille/certificatCS/$nomServeur.pem ./archive
#FIN - REVOCATION CERTIFICAT SERVEUR
#-----------------------------------------------------#
#REVOCATION CERTIFICAT CLIENT	
	elif [ $reponse = "3" ]; then
		sudo echo "Entrer le nom de votre certificat fille"
                read nomFille
                sudo echo "Entrer le nom de votre certificat client"
                read nomClient
                cd $chemin
                nb_files=$(find ./$nomFille/newcerts/ -type f | wc -l)
                i=0
                while [ "$i" -lt "$nb_files" ]
                do
                let i++
                fichier=0$i.pem
                cmp -s ./$nomFille/certificatCS/$nomClient.pem ./$nomFille/newcerts/$fichier

                if [ $? -eq 0 ]; then
                        openssl ca -config ./$nomFille/openssl.cnf -name $nomFille -revoke ./$nomFille/newcerts/$fichier
                        openssl ca -gencrl -config ./$nomFille/openssl.cnf -extensions $nomClient -name $nomFille -crldays 1 -out ./$nomFille/crl.pem
                        openssl crl -in ./$nomFille/crl.pem -text -noout
                fi
                let i--
                let i++
                done
		mv $nomFille/certificatCS/$nomClient.crs ./archive
                mv ./$nomFille/certificatCS/$nomClient.key ./archive
                mv ./$nomFille/certificatCS/$nomClient.pem ./archive
		mv .//$nomFille/certificatCS/$nomClient.p12 ./archive
	fi
#FIN - REVOCATION CERTIFICAT CLIENT
#FIN - REVOCATION CERTIFICAT
#-----------------------------------------------------#
#CREATION CERTIFICAT SERVEUR

elif [ $reponse = "3" ]; then
	sudo echo "Entrer le nom de votre certificat fille"
	read nomFille
	sudo echo "Entrer le nom pour votre certificat serveur"
	read nomServeur
	sudo echo "Entrer votre common name"
        read cn
        sudo echo "Entrer votre adresse email"
        read mail
	
        departement=$(grep "stateOrProvinceName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        ville=$(grep "localityName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        nom=$(grep "organizationName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        
	cd $chemin
	echo "[$nomServeur]
nsComment                       = "Certificat Serveur SSL"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
issuerAltName                   = issuer:copy
subjectAltName                  = DNS:www.webserver.com, DNS:www.webserver-bis.com
basicConstraints                = critical,CA:FALSE
keyUsage                        = digitalSignature, nonRepudiation, keyEncipherment
nsCertType                      = server
extendedKeyUsage                = serverAuth" >> $chemin/$nomFille/openssl.cnf
	
	sudo openssl genrsa -out $nomFille/certificatCS/$nomServeur.key -des3 1024
	sudo openssl req -new -key $nomFille/certificatCS/$nomServeur.key -out $nomFille/certificatCS/$nomServeur.crs -config ./$nomFille/openssl.cnf -subj "/C=FR/ST=$departement/L=$ville/O=$nom/CN=$cn/emailAddress=$mail"
	sudo openssl ca -out $nomFille/certificatCS/$nomServeur.pem -name $nomFille -config ./$nomFille/openssl.cnf -extensions $nomServeur -infiles $nomFille/certificatCS/$nomServeur.crs
#FIN - CREATION CERTIFICAT SERVEUR
#-----------------------------------------------------#
#CREATION CERTIFICAT CLIENT

elif [ $reponse = "4" ]; then
	sudo echo "Entrer le nom de votre certificat fille"
        read nomFille
        sudo echo "Entrer le nom pour votre certificat client"
        read nomClient
        sudo echo "Entrer votre common name"
        read cn
        sudo echo "Entrer votre adresse email"
        read mail
	
	departement=$(grep "stateOrProvinceName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        ville=$(grep "localityName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        nom=$(grep "organizationName_default" $chemin/$nomFille/openssl.cnf | cut -d" " -f3)
        
	cd $chemin
	echo "[$nomClient]
nsComment                       = "Certificat Client SSL"
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid,issuer:always
issuerAltName                   = issuer:copy
subjectAltName                  = critical,email:copy,email:user-bis@domain.com,email:user-ter@domain.com
basicConstraints                = critical,CA:FALSE
keyUsage                        = digitalSignature, nonRepudiation
nsCertType                      = client
extendedKeyUsage                = clientAuth" >> $chemin/$nomFille/openssl.cnf

	sudo openssl genrsa -out $nomFille/certificatCS/$nomClient.key -des3 1024
	sudo openssl req -new -key $nomFille/certificatCS/$nomClient.key -out $nomFille/certificatCS/$nomClient.crs -config ./$nomFille/openssl.cnf -subj "/C=FR/ST=$departement/L=$ville/O=$nom/CN=$cn/emailAddress=$mail"
	sudo openssl ca -out $nomFille/certificatCS/$nomClient.pem -name $nomFille -config ./$nomFille/openssl.cnf -extensions $nomClient -infiles $nomFille/certificatCS/$nomClient.crs
	sudo openssl pkcs12 -export -inkey $nomFille/certificatCS/$nomClient.key -in $nomFille/certificatCS/$nomClient.pem -out $nomFille/certificatCS/$nomClient.p12 -name "Certificat client"
#FIN - CREATION CERTIFICAT CLIENT
fi 
