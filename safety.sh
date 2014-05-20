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
#                                   known bugs                                          #
#                                   None so far                                         #
#                     Please report bugs to info@webbhatt.com                           #
#########################################################################################

# ~~~~~~~~~~ Environment Setup ~~~~~~~~~~ #
. ./environment
# ~~~~~~~~~~ Environment Setup ~~~~~~~~~~ #
#info
#Author Johan "Saint" B�rjesson

#################################Start script and validation####################################
#
# Till en börja kommer detta se ut som majjens script. skriver detta som en grund för att kunna vidare modifiera enligt egna preferenser.
# 
cd /usr/local/sbin

lista() {
  echo 'ipv6'
# ip6tables -L
  ip6tables-save
  echo 'ipv4'
# iptables -L
  iptables-save
}

resetta() {
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F
  iptables -X
  ip6tables -F
echo "Iptables är nu fixat"
lista
}
for (( i=30; i>0; i--)); do
    printf "\rStarting script in $i seconds.  Hit any key to continue."
    read -s -n 1 -t 1 key
    if [ $? -eq 0 ]
    then
        break
    fi
done
