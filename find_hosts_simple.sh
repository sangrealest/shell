#!/bin/bash
#author:shanker
#date:2012/6/21
set -u
HOST="192.168.196."
trap "exit" 2 3
for i in $(seq 1 25)
    do
    ping -c 1 -W 1 "$HOST$i" &>/dev/null
    if [ $? -eq 0 ]
    then
    echo ""$HOST$i" is alive"
    else
    echo ""$HOST$i" is down"
    fi
    done
