#!/bin/bash
#Author: Shanker
#Time: 2016/06/08

#set -e
#set -u
#you have to install linux-fincore
if [ ! -f /usr/local/bin/linux-fincore ]
then
    echo "You haven't installed linux-fincore yet"
    exit
fi

#find the top 10 processs' cache file
ps -e -o pid,rss|sort -nk2 -r|head -10 |awk '{print $1}'>/tmp/cache.pids
#find all the processs' cache file
#ps -e -o pid>/tmp/cache.pids

if [ -f /tmp/cache.files ]
then
    echo "the cache.files is exist, removing now "
    rm -f /tmp/cache.files
fi

while read line
do
    lsof -p $line 2>/dev/null |awk '{print $9}' >>/tmp/cache.files 
done</tmp/cache.pids


if [ -f /tmp/cache.fincore ]
then
    echo "the cache.fincore is exist, removing now"

    rm -f /tmp/cache.fincore
fi

for i in `cat /tmp/cache.files`
do

    if [ -f $i ]
    then

        echo $i >>/tmp/cache.fincore
    fi
done

linux-fincore -s  `cat /tmp/cache.fincore`

rm -f /tmp/cache.{pids,files,fincore}
