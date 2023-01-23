######ScriptALD.sh created for test KT######
#!/bin/bash

#set -x # - use for debugging

#declare variables
domain_name=local.example.ru
name_network_server=dns.local.example.ru
name_network_client=arm.local.example.ru
network_server=192.168.1.1
network_client=192.168.1.3
netmask=255.255.255.0

if dpkg -l | grep "ald-server" > /dev/null 2>&1
    then
	echo "Server initialized"
#set domain name for server
	sed -i "s/${HOSTNAME}/${name_network_server}/g"								/etc/hosts
	sed -i "s/127.0.1.1/${network_server}/g"								/etc/hosts
	hostnamectl set-hostname $name_network_server
	
#configuring local DNS server
#intall packet for DNS
	apt install bind9 -y > /dev/null 2>&1

	apt install dnsutils -y > /dev/null 2>&1


		sed -i 's\// forwarders\forwarders\g' 								/etc/bind/named.conf.options
		sed -i '14s\//\\g' 										/etc/bind/named.conf.options
		sed -i "14s/0.0.0.0;/${network_server};/g" 							/etc/bind/named.conf.options
		sed -i '15s\//\\g' 										/etc/bind/named.conf.options
		sed -i '24s/any/none/g' 									/etc/bind/named.conf.options
		echo "listen-on {
			127.0.0.1
			};" >> 											/etc/bind/named.conf.options
	 	
		
echo "zone \"${domain_name}\"	{
		      type master;
		      file \"/etc/bind/zones/db.${domain_name}\";
			};

		      zone \"1.168.192.in-addr.arpa\" {
		      type master;
			file \"/etc/bind/zones/db.1.168.192\";
			};" >> 											/etc/bind/named.conf.local
#create copy for config		
	mkdir /etc/bind/zones
	cp /etc/bind/db.local /etc/bind/zones/db.${domain_name}
	cp /etc/bind/db.127 /etc/bind/zones/db.1.168.192
	chown -R bind:bind /etc/bind/zones
	
		sed -i "5s/localhost. root.localhost./${name_network_server}. admin.${domain_name}./g"		/etc/bind/zones/db.${domain_name}
		sed -i '12s/@//g' 										/etc/bind/zones/db.${domain_name}
		sed -i "12s/localhost./${name_network_server}./g" 						/etc/bind/zones/db.${domain_name}
		sed -i "13s/@/${name_network_server}./g" 							/etc/bind/zones/db.${domain_name}
		sed -i "13s/127.0.0.1/${network_server}/g" 							/etc/bind/zones/db.${domain_name}
		sed -i "14s/@/${name_network_client}./g" 								/etc/bind/zones/db.${domain_name}
		sed -i '14s/AAAA/A/g' 										/etc/bind/zones/db.${domain_name}
		sed -i "14s/::1/${network_client}/g" 								/etc/bind/zones/db.${domain_name}

		sed -i "5s/localhost. root.localhost./${name_network_server}. admin.${domain_name}./g" 		/etc/bind/zones/db.1.168.192
		sed -i "12s/localhost./${name_network_server}./g" 						/etc/bind/zones/db.1.168.192
		sed -i '12s/@//g' 										/etc/bind/zones/db.1.168.192
		sed -i '13s/1.0.0/1/g' 										/etc/bind/zones/db.1.168.192
		sed -i "13s/localhost./${name_network_server}./g" 						/etc/bind/zones/db.1.168.192
		echo "4	IN	PTR	${name_network_client}" >> 						/etc/bind/zones/db.1.168.192
		
		rndc reload
	
	sed -i "s/.example.ru/.${domain_name}/g"								/etc/ald/ald.conf
	sed -i "s/astra.example.ru/${name_network_server}/g"							/etc/ald/ald.conf
	sed -i 's/SERVER_ON=0/SERVER_ON=1/g'									/etc/ald/ald.conf
	sed -i 's/CLIENT_ON=0/CLIENT_ON=1/g'									/etc/ald/ald.conf
	sed -i "s/DONTFOGET/${name_network_server}/g"								/etc/ald/ald.conf
	echo "SERVER_EXPORT_DIR=/ald_export_home
	      CLIENT_MOUNT_DIR=/ald_home" >> 									/etc/ald/ald.conf
	      ald-init init

sleep 2s

#configure dhcp 

apt install isc-dhcp-server -y
        sleep 5
        sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g'							/etc/default/isc-dhcp-server
        sed -i 's/INTERFACESv6=""/#INTERFACESv6=""/g'							        /etc/default/isc-dhcp-server
        systemctl restart isc-dhcp-server
        
sed -i "7s/example.org/${domain_name}/g"                                                                        /etc/dhcp/dhcpd.conf
sed -i "8s/ns1.example.org, ns2.example.org/${name_network_server}/g"                                           /etc/dhcp/dhcpd.conf
sed -i '21s/#authoritative;/authoritative;/g'                                                                   /etc/dhcp/dhcpd.conf
sed -i 's/#subnet 10.5.5.0 netmask 255.255.255.224/subnet 192.168.1.0 netmask 255.255.255.0 /g'                 /etc/dhcp/dhcpd.conf 
sed -i 's/range 10.5.5.26 10.5.5.30/range 192.168.1.2 192.168.1.5/g'                                            /etc/dhcp/dhcpd.conf
sed -i "52s/ns1.internal.example.org/${name_network_server}/g"                                                  /etc/dhcp/dhcpd.conf
sed -i "53s/internal.example.org/${domain_name}/g"                                                              /etc/dhcp/dhcpd.conf
sed -i '54s/10.5.5.1/192.168.1.10/g'                                                                            /etc/dhcp/dhcpd.conf 
sed -i "55s/10.5.5.31/${domain_name}/g"                                                                         /etc/dhcp/dhcpd.conf
 
echo "subnet 192.168.1.0 netmask ${netmask} {
        option routers 192.168.1.10;
        option subnet-mask 255.255.255.0;
        option domain-search \"${domain_name}\";
        option domain-name-servers $network_server;
        range 192.168.1.3 192.168.1.5;
        }" >>            /etc/dhcp/dhcpd.conf
  
#give static ip to client
 
echo "host arm {
        hardware ethernet 00:00:00:00:00:00;
        fixed-address ${network_client};
    }" >>               /etc/dhcp/dhcpd.conf
 
#add to autostart and start DHCP
        systemctl enable isc-dhcp-server.service
        systemctl start isc-dhcp-server.service
#add to listen 67 port
        ufw allow 67/udp
        ufw reload
        ufw show

        echo "ALD-Server successfully configured"

	#configure ntp for server
   	#make bkp ntp.conf
	cp /etc/ntp.conf $PWD/ntp.conf_bkp_server_$(date +%d_%m_%Y_%H_%M)
		sed -i 's/pool 0/#pool 0/g' 									/etc/ntp.conf
		sed -i 's/pool 1/#pool 1/g' 									/etc/ntp.conf
		sed -i 's/pool 2/#pool 2/g' 									/etc/ntp.conf
		sed -i 's/pool 3/#pool 3/g' 									/etc/ntp.conf
		sed -i "s/restrict 192.168.123.0 mask 255.255.255.0 notrust/restrict ${network_server} mask ${netmask} nomodify notrap/g" /etc/ntp.conf
		echo "server 127.127.1.0
		      fudge 127.127.1.0 stratum 10" >> 								/etc/ntp.conf
		
                systemctl enable ntp > /dev/null 2>&1 
		systemctl start ntp
		
		    if ntpq -p |grep "=" > /dev/null 2>&1
			then
			echo "Сервер ntp успешно запущен"
			    else ntpq -p | grep "Connection refused" > /dev/null 2>&1
				echo "Сервер ntp не запущен"
		    fi
    	    elif dpkg -l | grep "ald-client" > /dev/null 2>&1
    then
    
	echo "Client initialized"
#set domain name for client 
	sed -i "s/${HOSTNAME}/${name_network_client}/g"								/etc/hosts
	hostnamectl set-hostname $name_network_client
		sed -i "s/127.0.1.1/${network_client}/g"							/etc/hosts
		
	ald-client join $name_network_server

        echo "ALD-Client successfully configured"
	    
#configure ntp.conf for client
	cp /etc/ntp.conf $PWD/ntp.conf_bkp_client_$(date +%d_%m_%Y_%H_%M)
		echo "server 192.168.1.1 prefer" >> 								/etc/ntp.conf
		systemctl enable ntp > /dev/null 2>&1
		systemctl start ntp

        echo "auto eth0
        iface eth0 inet dhcp" >> /etc/network/interfaces   
        systemctl restart networking
 
		    if ntpq -p |grep "${network_server}" > /dev/null 2>&1
			then
			echo "Client ntp successfully synchronised with server"
			    else ntpq -p | grep "Connection refused" > /dev/null 2>&1
				echo "Fail to ntp start"
		    fi    
	    else dpkg -l | grep "ald-client" > /dev/null 2>&1
	echo "Initialized faild"
       
fi
