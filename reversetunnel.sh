#!/bin/bash
#Author Viktor "Volten" Voltaire
echo -e "Enter the host you want to tunnel through"
read hostip
echo -e "Enter the port you want to forward with (example 2210)"
read forport
echo -e "Enter localhost or the ip of another host, like a printer"
read localip
echo -e "Enter the port of the service you will tunnel (example 22 for ssh)"
read localport
echo -e "Enter the username for the gateway"
read user

ssh -N -f -R $hostip:$forport:$localip:$localport $user@$hostip
echo ""
echo "Make sure that the gateway has GatewayPorts clientspecified in sshd_config"
echo ""
read -t 20 -r -p "Do you want to terminate the ssh tunnel? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
       killall ssh
;;
    *)
        echo ""
        echo "GG"
;;
esac
