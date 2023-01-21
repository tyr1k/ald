#!/bin/bash

network_server=192.168.1.1
network_client1=192.168.1.2
network_client2=192.168.1.3
netmask=255.255.255.0

if dpkg -l | grep "ald-server" > /dev/null 2>&1
  then
    echo "Server initialized"
#Configurate ntp for server
#Create bkp ntp.conf
    cp /etc/ntp.conf $PWD/ntp.conf_bkp_$(date +%d_%m_%Y_%H_%M)
  #Change setting for our configuration
    sed -i 's/pool 0/#pool 0/g'            /etc/ntp.conf
    sed -i 's/pool 1/#pool 1/g'            /etc/ntp.conf
    sed -i 's/pool 2/#pool 2/g'            /etc/ntp.conf
    sed -i 's/pool 3/#pool 3/g'            /etc/ntp.conf
    sed -i "s/#restrict 192.168.123.0 mask 255.255.255.0 notrust/restrict ${network_server} mask ${netmask} nomodify notrap/g" /etc/ntp.conf
    echo "server 127.127.1.0" >>           /etc/ntp.conf
    echo "fudge 127.127.1.0 stratum 10" >> /etc/ntp.conf
    
    systemctl enable ntp > /dev/null 2>&1
    systemctl start ntp
      if ntpq -p | grep "=" > /dev/null 2>&1
        then
        echo "Server ntp successfully started"
          else ntpq -p | grep "Connection refused" > /dev/null 2>&1
      fi
 elif dpkg -l | grep "ald-client" > /dev/null 2>&1
  then
    echo "Client initialized"
      else dpkg -l | grep "ald-client" > /dev/null 2>&1
    echo "Initialized faild" && exit -1
fi
