#!/bin/bash
#Author Volten
echo "Do you need to add GatewayPorts clientspecified to your DMZ? (y/n)"
read string
case "$string" in
    [yY] | [yY][eE][sS])
        echo -e "Enter the IP to DMZ server"
        read dmzip
        echo -e "Enter the ssh port (normally 22)"
        read dmzport
        echo -e "Enter the ssh username"
        read dmzuser
        ssh $dmzuser@$dmzip -p $dmzport "echo GatewayPorts clientspecified >> /etc/ssh/sshd_config"
        echo ""
        echo "Gratz now ur tunnel is ready to be setup"
         ;;
    [nN] | [nN][oO])
        echo "Continue with somethingelse"
        ;;
    *) echo "Now what the hell do you mean with '$string'" ;;
esac
