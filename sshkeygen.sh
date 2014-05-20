#!/bin/bash

echo -e "How big should your key be? (1024, 2048, 4096)"
read sshbit
echo -e "What username on the remote host?"
read ruser
echo -e "What is the ip or hostname of the remote host?"
read rhost

ssh-keygen -b $sshbit
ssh-copy-id $ruser@$rhost
ssh-add
