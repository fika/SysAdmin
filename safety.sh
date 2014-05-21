#!/bin/bash
# Author Volten, Saint

echo -e "Please enter Iptables rule:"
read iprule
$iprule

resetta() {
iptables-restore restora.fil
}

touch /var/run/FulWall

echo -e "Skriv yes för att spara annars avbryts det om 10" 
read -t 10 answer  
if [ "$answer"  == "yes" ] ; then
rm -f /var/run/FulWall
cp restora.fil restora.back
iptables-save > restora.fil
echo -e "Rule has been added"
else
resetta
echo -e "Rule has not been added due to timeout"
fi
