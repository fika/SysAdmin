#!/bin/bash
echo -e "what port do you want to use? (example:9001)"
read lport
echo -e "what host to you want to tunnel via? (maybe your home ip?)"
read rhost
echo -e "what user should we log in as? maybe $USER?"
read username
echo -e "are you using another ssh port at home? if unsure, type 22"
read sshport
ssh -D $lport $username@$rhost -p $sshport -N &
echo -e "Now point your socksproxy in your browser to localhost:$lport"
