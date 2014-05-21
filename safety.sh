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
temp="$folder/temp"
now=$(date +"%d-%m-%y_%H%M")
outfile="iptables.$now"
#

iptables-save > $temp

echo -e "Enter Iptables rule:"
read iprule
$iprule

echo -e "Vill du spara (yes) annars avbryts regeln om 20 sec "
read -t 20 answer

if [ "$answer"  == "yes" ] ; then

mv $folder/iptables.* $old/ 2> /dev/null
iptables-save > $folder/$outfile
rm $temp
echo -e "Rule has been added"

else

restore
echo -e "Rule has not been added due to timeout"
rm $temp

fi
