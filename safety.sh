#!/bin/bash
# Author Volten, Saint
# LOVE HJÄLPTE OCKSÅ TILL

#Variablar
firsttime="0"
temp="temp"
now=$(date +"%d-%m-%y_%H%M_%S")
outfile="iptables.$now"
#

#Måste köras som root
if [[ $EUID -ne 0 ]]; then
echo -e "${WARNING}Script must be run as root!${END}"
exit 1
else

if [ "$firsttime" == "0" ] ;
then
echo -e "What folder do you want to use? (example /var/bak)"
read instfolder
mkdir -p $instfolder
echo -e "What folder do you want to move the old iptables files? (example /var/bak/old)"
read instold
mkdir -p $instold

sed -i '0,/firsttime="0"/s//firsttime="1"/' saftey.sh

sed -i "7i\
folder=$instfolder" saftey.sh

sed -i "8i\
old=$instold" saftey.sh

read -r -p "Do you want to save your current iptables? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
        echo -e "\nInstall complete, reloading the script"
        iptables-save > $instfolder/$outfile
        bash saftey.sh
;;
    *)
        echo -e "\nInstall complete, reloading the script"
        bash saftey.sh
;;
esac

else


#Funktionen
restore() {
iptables-restore $temp
}

iptables-save > $temp

echo -e "Enter Iptables rule:"
read iprule
$iprule

read -t 20 -r -p "Do you want to save the rule? [y/N] " response
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

fi
fi
