#!/bin/bash

#under the directory have toplist program and gamesys.conf 2016040{1..9}* db folders, with the program, every time run it there should be the db folder named dbhomewdb

for ((i=4;i<=15;i++))
do

    CURRENT_DIR=$(ls -l | grep 20160|head -1|awk '{print $9}')
    if [ -d dbhomewdb ]
    then
#        echo "dbhomewdb existed, deleting now"
        rm -rf dbhomewdb
    fi
    mv $CURRENT_DIR dbhomewdb

    if [ ! -z $CURRENT_DIR ]
    then
 
        ./toplist gamesys.conf query > $i.21.179 2>&1 

    fi
done
