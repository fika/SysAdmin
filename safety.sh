#!/bin/bash
# Author Volten, Saint
. ./environment
# Buggar som är kända, 
# När man har blivit utsparkad vill man bara se att reglerna är borta inte valet om att ta bort Fulwall
echo -n "Please enter Iptables rule:"
read iprule
$iprule
resetta() {
iptables-restore restora.fil
}

touch /var/run/FulWall.sh

( sleep 30 ; rm -f /var/run/FulWall && resetta ) &
#
# if true
# ls /var/run/FulWall
# do
# resetta
read -r -p "Would you like to delete the FulWall file and save your changes to the default setup of iptables? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
rm -f /var/run/FulWall.sh
cp restora.fil restora.back
iptables-save > restora.fil 
;;
    *)
:
;;
esac
echo -e "${SUCCESS}[*] Rule have been added to default setup of iptables ${END}"
#om du inte är utslängd	kan du nu bestämma att ta bort skiten å	spara till din standarfw

exit 0
