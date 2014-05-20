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
#ENTER MENU
clear
echo ""
echo ""
echo -e "${RED_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${END}"
echo -e "${RED_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~             IPTABLES            ~~~~~~~~~~~~~~~~~~~~~~~~~${END}"
echo -e "${RED_TEXT}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${END}"
echo ""
echo ""
echo -e "${BLUE_TEXT}1) List existing iptables configuration.${END}"
echo ""
echo -e "${BLUE_TEXT}2) Start, stop or restart firewall.${END}"
echo ""
echo -e "${BLUE_TEXT}3) Sample text here.${END}"
echo ""
echo -e "${BLUE_TEXT}4) Sample text here.${END}"
echo ""
echo -e "${BLUE_TEXT}5) Sample text here.${END}"
echo ""
echo -e "${BLUE_TEXT}6) Sample text here.${END}"
echo ""
echo -e "${BLUE_TEXT}7) Sample text here.${END}"
echo ""
echo -e "${BLUE_TEXT}8) Kill all open tunnels.${END}"
echo ""
echo -e "${BLUE_TEXT}9) Quit the program${END}"

# Look for options
echo -e ""
echo -e "${WARP}SELECT:${END}"
read option



if [ "$option" = "1" ]; then
	#SHOW IPTABLES RULES
	iptables -L -n -v

elif [ "$option" = "2" ]; then
	#STARTING sample
	echo -e "${BLUE_TEXT}What do you want to do?{END}"
	echo -e "${BLUE_TEXT}1) Start firewall.{END}"
	echo -e "${BLUE_TEXT}2) Stop firewall.{END}"
	echo -e "${BLUE_TEXT}3) Restart firewall{END}"
	read twoption
		if [ "$twoption" = "1" ]; then
			service iptables start
		elif [ "$twoption" = "2" ]; then
			service iptables stop
		elif [ "$twoption" = "3" ]; then
			service iptables restart
		else
			cowsay 'TRY AGAIN, FOOL!'
		fi

elif [ "$option" = "3" ]; then
	#STARTING sample
	bash sample

elif [ "$option" = "4" ]; then
	#STARTING sample
	bash sample

elif [ "$option" = "5" ]; then
	#STARTING sample
	bash sample

elif [ "$option" = "6" ]; then
	#STARTING sample
	python sample

elif [ "$option" = "7" ]; then
	#STARTING sample
	bash sample

elif [ "$option" = "8" ]; then
	#KILL ALL
	killall ssh

elif [ "$option" = "9" ]; then
	echo "Exiting"
	exit 0
else
echo "Please try again."
bash SysAdmin
fi
