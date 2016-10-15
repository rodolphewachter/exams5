#!/bin/bash

chemin="/opt/firewall"
cheminScriptFinal="/opt/firewall/firewallMV.sh"
interface="192.168.0.10"
interface2="192.168.1.10"
echo "1-Activation du nat"
echo "2-Desactivation du nat"
echo "3-Configurer une règle de redirection"
echo "4-Configurer une règle de filtrage"
echo "5-Supprimer une règle de redirection"
echo "6-Supprimer une règle de filtrage"
read reponse

#ACTIVATION NAT
#---------------------------------
if [ $reponse = "1" ];then
	sed -i 's/#iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE/iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE/g' $cheminScriptFinal
echo "NAT établie"
#FIN - ACTIVATION NAT
#---------------------------------

#DESACTIVATION NAT
#---------------------------------
elif [ $reponse = "2" ];then
	sed -i 's/iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE/#iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE/g' $cheminScriptFinal
echo "Désactivation du nat"

#FIN - DESATIVATION NAT
#----------------------------------

#REGLE DE REDIRECTION
#----------------------------------
elif [ $reponse = "3" ];then
	echo "Protocole : "
	echo "1 - UDP"
	echo "2 - TCP"
	read protocole
	echo "IP : "
	read ip_dst
	echo "Port destination externe : "
	read port_dst_ext
	echo "Port destination interne : "
	read port_dst_int
	echo "Action : "
        echo "1 - ACCEPT "
        echo "2 - DROP "
        read action
	
	if [ $protocole -eq "1" ];then
		if [ $action -eq "1" ];then
			echo "iptables -t nat -A PREROUTING -i $interface -p udp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int" >> $chemin/redirection.sh
   			echo "iptables -A FORWARD -i $interface -o $interface2 -p udp --dport $port_dst_ext -m state --state NEW -j ACCEPT" >> $chemin/redirection.sh
		else 
			echo "iptables -t nat -A PREROUTING -i $interface -p udp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int" >> $chemin/redirection.sh
                        echo "iptables -A FORWARD -i $interface -o $interface2 -p udp --dport $port_dst_ext -m state --state NEW -j DROP" >> $chemin/redirection.sh
		fi
	elif [ $protocole -eq "2" ];then
		if [ $action -eq "1" ];then
			echo "iptables -t nat -A PREROUTING -i $interface -p tcp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int" >> $chemin/redirection.sh
			echo "iptables -A FORWARD -i $interface -o $interface2 -p tcp --dport $port_dst_ext -m state --state NEW -j ACCEPT" >> $chemin/redirection.sh
		else
			echo "iptables -t nat -A PREROUTING -i $interface -p tcp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int" >> $chemin/redirection.sh
                        echo "iptables -A FORWARD -i $interface -o $interface2 -p tcp --dport $port_dst_ext -m state --state NEW -j DROP" >> $chemin/redirection.sh
		fi
	else
		echo "Protocole incorrect"
		./firewallScript.sh
	fi

#FIN REGLE DE REDIRECTION
#----------------------------------

#REGLE DE FILTRAGE
#------------------------------------
elif [ $reponse = "4" ];then
	ip_src_f=""
	ip_dst_f=""
	port_dst_f=""
	port_src_f=""
	protocole="None"
	type_filtrage="None"
	action="None"
	regle="None"
	echo "Type : "
	echo "1-INPUT "
	echo "2-OUTPUT "
	echo "3- FORWARD "
	read type_filtrage
	echo "Protocole : "
	echo "1 - UDP"
	echo "2 - TCP"
	read protocole
	echo "IP source : (Par default = None)"
	read ip_src
	echo "IP destination : (Par default = None)"
	read ip_dst
	echo "Port source : (Par default = None)"
	read port_src
	echo "Port destionation : (Par default = None)"
	read port_dst
	echo "Action : "
	echo "1 - ACCEPT "
	echo "2 - DROP "
	read action

# Test des variables

	if [ $ip_src == "" ]; then
		ip_src_f=""
	else
		ip_src_f="-s $ip_src"
	fi

	if [ $ip_dst == "" ]; then
		ip_dst_f=""
	else
		ip_dst_f="-d $ip_dst"
	fi

	if [ $port_src == "" ]; then
		port_src_f=""
	else
		port_src_f="--sport $port_src"
	fi

	if [ $port_dst == "" ]; then
		port_dst_f=""
	else
		port_dst_f="--dport $port_dst"
	fi
	
#Application du filtrage
	
	if [ $protocole -eq "1" ];then
                if [ $type_filtrage -eq "1" ];then                        
                	if [ $action -eq "1" ];then
				echo "iptables -t filter -A INPUT $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A INPUT $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j DROP" >> $chemin/drop.sh
			fi
                elif [ $type_filtrage -eq "2" ];then                        
               		if [ $action -eq "1" ];then
				echo "iptables -t filter -A OUTPUT $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A OUTPUT $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j DROP" >> $chemin/drop.sh
			fi 
                elif [ $type_filtrage -eq "3" ];then
			if [ $action -eq "1" ]; then
                        	echo "iptables -t filter -A FORWARD $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A FORWARD $ip_src_f $ip_dst_f -p udp $port_src_f $port_dst_f -m state --state NEW -j DROP" >> $chemin/drop.sh
			fi
                else
                        echo "Type non reconnu !"
			./firewallScript.sh
                fi

        elif [ $protocole -eq "2" ];then
                if [ $type_filtrage -eq "1" ];then
                	if [ $action -eq "1" ];then
				echo "iptables -t filter -A INPUT $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A INPUT $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j DROP" >> $chemin/drop.sh	
			fi
                elif [ $type_filtrage -eq "2" ];then
                        if [ $action -eq "1" ];then
				echo "iptables -t filter -A OUTPUT $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A OUTPUT $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j DROP" >> $chemin/drop.sh
			fi
                elif [ $type_filtrage -eq "3" ];then
                        if [ $action -eq "1" ];then
				echo "iptables -t filter -A FORWARD $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j ACCEPT" >> $chemin/accept.sh
			else
				echo "iptables -t filter -A FORWARD $ip_src_f $ip_dst_f -p tcp $port_src_f $port_dst_f -m state --state NEW --syn -j DROP" >> $chemin/drop.sh
			fi
                else
                        echo "Type non reconnu !"
			./firewallScript.sh
                fi
        else
                echo "Protocole non correct !"
		./firewallScript.sh
        fi
#FIN - REGLE FILTRAGE
#------------------------------
#SUPPRESSION REGLE REDIRECTION

elif [ $reponse = "5" ];then
	ip="None"
	port_dst_int="None"
	port_dst_ext="None"
	protocole="None"
	echo "Protocole : "
	echo "1 - UDP"
	echo "2 - TCP"
	read protocole
	echo "IP : "
	read ip_dst
	echo "Port destination externe : "
	read port_dst_ext
	echo "Port destination interne : "
	read port_dst_int
	echo "Action : "
        echo "1 - ACCEPT "
        echo "2 - DROP "
        read action	

#ECRITURE DE LA REGLE DANS UNE VARIABLE
	if [ $protocole -eq "1" ];then
		if [ $action -eq "1" ];then
			regle="iptables -t nat -A PREROUTING -i $interface -p udp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int"
    			regle2="iptables -A FORWARD -i $interface -o $interface2 -p udp --dport $port_dst_ext -m state --state NEW -j ACCEPT"
		else
			regle="iptables -t nat -A PREROUTING -i $interface -p udp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int"
                        regle2="iptables -A FORWARD -i $interface -o $interface2 -p udp --dport $port_dst_ext -m state --state NEW -j DROP"
		fi
	elif [ $protocole -eq "2" ] ; then
		if [ $action -eq "1" ];then
			regle="iptables -t nat -A PREROUTING -i $interface -p tcp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int"
			regle2="iptables -A FORWARD -i $interface -o $interface2 -p tcp --dport $port_dst_ext -m state --state NEW -j ACCEPT"
		else
			regle="iptables -t nat -A PREROUTING -i $interface -p tcp --dport $port_dst_ext -j DNAT --to-destination $ip_dst:$port_dst_int"
                        regle2="iptables -A FORWARD -i $interface -o $interface2 -p tcp --dport $port_dst_ext -m state --state NEW -j DROP"
		fi
	else
		echo "Protocole non correct !"
		./firewallScript.sh
	fi
sed -i "s/$regle/ /g" $chemin/redirection.sh
sed -i "s/$regle2/ /g" $chemin/redirection.sh
#sed -i '/^$/d' $chemin/redirection.sh
echo "Votre rêgle de redirection à bien été supprimer :"
echo $regle
echo $regle2
#FIN - SUPPRESSION REGLE REDIRECTION
#----------------------------------
#SUPPRESSION REGLE FILTRAGE

elif [ $reponse = "6" ];then
	ip_src_f=""
        ip_dst_f=""
        port_dst_f=""
        port_src_f=""
        protocole="None"
        type_filtrage="None"
        action="None"
        regle="None"
        echo "Type : "
        echo "1-INPUT "
        echo "2-OUTPUT "
        echo "3- FORWARD "
        read type_filtrage
        echo "Protocole : "
        echo "1 - UDP"
        echo "2 - TCP"
        read protocole
        echo "IP source : (Par default = None)"
        read ip_src
        echo "IP destination : (Par default = None)"
        read ip_dst
        echo "Port source : (Par default = None)"
        read port_src
        echo "Port destionation : (Par default = None)"
        read port_dst
        echo "Action :(ACCEPT/DROP)"
        read action
#Suppression règle filtrage
	#A corriger
	if [ $protocole -eq "1" ];then
		if [ $type_filtrage -eq "1" ];then
			regle="iptables -t filter -A INPUT -s $ip_src -d $ip_dst -p udp --sport $port_src --dport $port_dst -m state --state NEW -j $action" 
		elif [ $type_filtrage -eq "2" ];then
			regle="iptables -t filter -A OUTPUT -s $ip_src -d $ip_dst -p udp --sport $port_src --dport $port_dst -m state --state NEW -j $action" 
		elif [ $type_filtrage -eq "3" ];then
			regle="iptables -t filter -A FORWARD -s $ip_src -d $ip_dst -p udp --sport $port_src --dport $port_dst -m state --state NEW -j $action" 
		else 
			echo "Type non reconnu !"
		fi
	elif [ $protocole -eq "2" ];then
		if [ $type_filtrage -eq "1" ];then
			regle="iptables -t filter -A INPUT -s $ip_src -d $ip_dst -p tcp --sport $port_src --dport $port_dst -m state --state NEW --syn -j $action" 
		elif [ $type_filtrage -eq "2" ] ; then
			regle="iptables -t filter -A OUTPUT -s $ip_src -d $ip_dst -p tcp --sport $port_src --dport $port_dst -m state --state NEW --syn -j $action" 
		elif [ $type_filtrage -eq "3" ] ; then
			regle="iptables -t filter -A FORWARD -s $ip_src -d $ip_dst -p tcp --sport $port_src --dport $port_dst -m state --state NEW --syn -j $action" 
		else 
			echo "Type non reconnu !"
		fi
	else 
		echo "Protocole non correct !"
	fi
	#A corriger
	sed -i "s/$regle/ /g" $chemin/redirection.sh
	echo "Votre rêgle de filtrage à bien été supprimer :"
	echo $regle
fi

#sudo bash $cheminScriptFinal
