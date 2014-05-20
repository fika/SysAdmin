#!/bin/bash

#exempel på en standardFW


iptables -F
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -A INPUT -p tcp -m tcp ! --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j DROP
iptables -A INPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG FIN,SYN,RST,PSH,ACK,URG -j DROP
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 2210 -j ACCEPT
iptables -A INPUT -s 10.10.4.195/32 -p tcp -m tcp --dport 22 -j ACCEPT






#!/bin/bash

#exempel, här kan man ha en entry read grejj
iptables -F

resetta() {
bash /home/student/standardfw.sh
echo 'regler borta'
}

touch /var/run/FulWall.sh

( echo '60 sekunder kvar'; sleep 30  ; echo '30 sekunder kvar'; sleep 30 ; rm -f /var/run/FulWall && resetta ) &

#om du inte är utslängd	kan du nu bestämma att ta bort skiten å	spara till din standarfw

exit 0
