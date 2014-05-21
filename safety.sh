#!/bin/bash
# Author Volten, Saint

folder="/var/bak"
iptables-save > temp.fil

echo -e "Please enter Iptables rule:"
read iprule
$iprule
now=$(date +"%d-%m-%y_%H%M")
outfile="iptables.$now"

resetta() {
iptables-restore temp.fil
}

echo -e "Skriv yes för att spara annars avbryts det om 10" 
read -t 10 answer  

if [ "$answer"  == "yes" ] ; then

mv $folder/iptables.* $folder/old/
iptables-save > $folder/$outfile
rm temp.fil
echo -e "Rule has been added"

else

resetta
echo -e "Rule has not been added due to timeout"
rm temp.fil

fi
