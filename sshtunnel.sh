#!/bin/bash
echo -e "what port do you want to use? (example:9001)"
read lport
echo -e "what website are you trying to reach? (example:pornhub.com)"
read site
echo -e "what port is the website using? (usually 80)"
read rport
echo -e "what host to you want to tunnel via? (maybe your home ip?)"
read rhost
echo -e "what user should we log in as? maybe $USER?"
read username
echo -e "are you using another ssh port at home? if unsure, type 22"
read sshport
ssh -L $lport:$site:$rport $username@$rhost -p $sshport -N &
echo -e "To visit $site, simply open a browser and point it to localhost:$lport"
