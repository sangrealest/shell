#!/bin/bash

DISK_LOG=/tmp/disk_use.tmp
DISK_TOTAL=`fdisk -l |awk '/^Disk.*bytes/&&/\/dev/{printf $2" ";printf "%d",$3;print "GB"}'`
USE_RATE=`df -h |awk '/^\/dev/{print int($5)}'`
for i in $USE_RATE; do
    if [ $i -gt 90 ];then
        PART=`df -h |awk '{if(int($5)=='''$i''') print $6}'`
        echo "$PART = ${i}%" >> $DISK_LOG
    fi  
done
echo "---------------------------------------"
echo -e "Disk total:\n${DISK_TOTAL}"
if [ -f $DISK_LOG ]; then
    echo "---------------------------------------"
    cat $DISK_LOG
    echo "---------------------------------------"
    rm -f $DISK_LOG
else
    echo "---------------------------------------"
    echo "Disk use rate less than 90% of the partition."
    echo "---------------------------------------"
fi  

