#!/bin/bash
# Author Volten, Saint
# LOVE HJÄLPTE OCKSÅ TILL

#Funktionen
restore() {
iptables-restore $temp
}

#Variablar
folder="/var/bak"
mkdir -p $folder
old="/var/bak/old"
mkdir -p $old
temp="temp"
now=$(date +"%d-%m-%y_%H%M_%S")
outfile="iptables.$now"
#

iptables-save > $temp

echo -e "Enter Iptables rule:"
read iprule
$iprule

read -t 20 -r -p "Do you want to save the rule? [y/N]" response
case $response in
[yY][eE][sS]|[yY])
        rm $temp
        mv $folder/* $old/ 2> /dev/null
        iptables-save > $folder/$outfile
        echo -e "\nRule has been added"

;;
    *)
        restore
        echo -e "\nRule has not been added"
;;
esac
