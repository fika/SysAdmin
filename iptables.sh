#!/bin/bash

#HÄR SKA DET BYGGAS ETT IPTABLES-SKRIPT :)

# ~~~~~~~~~~  SET VARIABLES  ~~~~~~~~~ #
#volten="SMAKA HS!"

# ~~~~~~~~~~  CREATE FUNCTIONS  ~~~~~~~~~ #
#cleanup()
#exempel
#{
#cowsay 'hej'
#}

# ~~~~~~~~~~  SETUP EXIT TRAP  ~~~~~~~~~ #
control_c()
# run if user hits control-c
{
echo -en "\n*** Ouch! Exiting ***\n"
cleanup
exit $?
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

# ~~~~~~~~~~  INITIALIZATION  ~~~~~~~~~ #

. ./environment

# ~~~~~~~~~~  ROOT CHECK! ~~~~~~~~~ #
FILE="/tmp/out.$$"
GREP="/bin/grep"
#Only root should run this.
if [[ $EUID -ne 0 ]]; then
	cowsay -f sodomized-sheep "Run as root." 1>&2
	exit 1
fi


# ~~~~~~~~~~  BEGINNING OF SCRIPT BELOW ~~~~~~~~~ #
echo -e "${BLUE_TEXT}TEST TEST TEST TEST${END}"

