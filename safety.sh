#!/bin/bash
# Author Volten, Saint
# Buggar som är kända,
# När man har blivit utsparkad vill man bara se att reglerna är borta inte valet om att ta bort Fulwall
echo -e "Please enter Iptables rule:"
read iprule
$iprule

resetta() {
iptables-restore restora.fil
}

touch /var/run/FulWall

( sleep 30 ; rm -f /var/run/FulWall && resetta ) &

read -r -p "Would you like to delete the FulWall file and save your changes to the default setup of iptables? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
rm -f /var/run/FulWall
cp restora.fil restora.back
iptables-save > restora.fil
echo -e "${SUCCESS}[*] Rule have been added to default setup of iptables and a backup has been created of the old ones.${END}"
;;
    *)
echo ""
echo "Your rule was not saved"
;;
esac
exit 0
