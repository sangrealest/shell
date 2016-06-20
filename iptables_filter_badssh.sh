#!/bin/bash
#Author: Shanker

#Use iptables to filter bad users who trying to crypt your ssh password if you are using password to logoin your server.

#If some try to contect your server 4 times within 60 seconds, then drop the session.

port=22
inet=eth1
echo "$0 -p ssh port(default is 22)  -i internet face(default is eth1)"
while getopts ":p:i:" opt
do
    case "$opt" in
    "p")
        port=$OPTARG
    ;;
    "i")
        inet=$OPTARG
    ;;
    *)
        echo "unknown args"
    ;;
    esac
done

iptables -I INPUT -p tcp --dport $port -i $inet -m state --state NEW -m recent --set
iptables -I INPUT -p tcp --dport $port -i $inet -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
