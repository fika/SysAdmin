#!/bin/bash
#####################################################################################################################
# #
# This script is written by Johan aka Saint, admin of Webbh4tt #
# This program is open source; you can redistribute it and/or modify it under the terms of the GNU General Public #
# The author bears no responsibility for malicious or illegal use. #
# #
# #
#####################################################################################################################

#########################################################################################
# known bugs #
# None so far #
# Please report bugs to info@webbhatt.com #
#########################################################################################

# ~~~~~~~~~~ Environment Setup ~~~~~~~~~~ #
. ./environment
# ~~~~~~~~~~ Environment Setup ~~~~~~~~~~ #
#info
#Author Johan "Saint" B�rjesson

#################################Start script and validation####################################
echo -n "Searching for tunnels"
while true
do
if ps -ef | grep "[s]sh -*"
then
echo -e "${SUCCESS}SSH tunnels are up${END}"
break
else
echo -e "${WARNING}SSH tunnels are down${END}"
echo -e "${RED_TEXT}Something is wrong please check your settings${END}"
read -r -p "Do you want to go configure your settings again? [y/N] " response
case $response in
[yY][eE][sS]|[yY])
bash sshtunnel.sh
;;
    *)
exit
:
;;
esac
fi
done
