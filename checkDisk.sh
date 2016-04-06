#!/bin/bash
#Author:Shanker

date=$(date +"%Y%m%d")

servers="./server_list"

function getResult(){
if [ ! -f disk.log.$date ]
then
    echo "=======Geting the log...========="
    for i in `cat $servers`
    do
         echo $i >>disk.log.$date
        ssh $i "/cygdrive/c/CGuardian/tools/MegaCli.exe -cfgdsply-aALL|grep -E -i 'err|fail'" >> disk.log.$date
    done
fi
}


function showFailure(){

echo -e "Predictive Failure Count is:\n"

cat disk.log.$date | awk '/Predictive Failure Count/ {s +=$NF} END { if(s>0) print s}'

echo -e "Media Error Count is : \n"

cat disk.log.$date | awk '/Media Error Count/ {m +=$NF} END { if(m<1000) print m}'

}

getResult
showFailure
