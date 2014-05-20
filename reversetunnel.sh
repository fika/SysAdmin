#!/bin/bash
#Author Volten
echo -e "Enter the host you want to tunnel through"
read hostip
echo -e "\nEnter the port you want to forward with (example 2210)"
read forport
echo -e "\nEnter localhost or the ip of another host, like a printer"
read localip
echo -e "\nEnter the port of the service you will tunnel (example 22 for ssh)"
read localport
echo -e "\nEnter the username for the gateway"
read user

ssh -N -f -R $hostip:$forport:$localip:$localport $user@$hostip
echo "\nMake sure that the gateway has GatewayPorts clientspecified in sshd_config\n"
read -r -p "Do you want to terminate the ssh tunnel? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
       killall ssh
;;
    *)
        echo "\nGG"
;;
esac
