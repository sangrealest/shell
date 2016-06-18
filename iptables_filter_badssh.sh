#!/bin/bash
#Author: Shanker

#Use iptables to filter bad users who trying to crypt your ssh password if you are using password to logoin your server.

#If some try to contect your server 4 times within 60 seconds, then drop the session.

port=22

iptables -I INPUT -p tcp --dport $port -i eth0 -m state --state NEW -m recent --set
iptables -I INPUT -p tcp --dport $port -i eth0 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
