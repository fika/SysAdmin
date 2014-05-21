#!/bin/bash
# Author Volten, Saint

current_table=$(iptables-save)

echo -e "Please enter Iptables rule:"
read iprule
$iprule
now=$(date +"%d-%m-%y_%H%M")
outfile="iptables.$now"

resetta() {
#iptables-restore restora.fil #KOMMENTERAR OCH TESTAR MED DATE
iptables-restore < $current_table
}

echo -e "Skriv yes för att spara annars avbryts det om 10" 
read -t 10 answer  
if [ "$answer"  == "yes" ] ; then
iptables-save > $outfile.back
echo -e "Rule has been added"
else
resetta
echo -e "Rule has not been added due to timeout"
fi
