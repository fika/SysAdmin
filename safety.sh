#!/bin/bash
# Author Volten, Saint
# LOVE HJÄLPTE OCKSÅ TILL

mkdir -p /var/bak/old
folder="/var/bak"
temp="/var/bak/temp.fil"
iptables-save > $temp

echo -e "Please enter Iptables rule:"
read iprule
$iprule
now=$(date +"%d-%m-%y_%H%M")
outfile="iptables.$now"

resetta() {
iptables-restore $temp
}

echo -e "Skriv yes för att spara annars avbryts det om 10"
read -t 10 answer

if [ "$answer"  == "yes" ] ; then

mv $folder/iptables.* $folder/old/ 2> /dev/null
iptables-save > $folder/$outfile
rm $temp
echo -e "Rule has been added"

else

resetta
echo -e "Rule has not been added due to timeout"
rm $temp

fi
