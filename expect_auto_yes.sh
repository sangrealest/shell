#!/bin/bash
while read ip
    do
       expect -c "
       set timeout -1
       spawn ssh  $ip \'exit\' 
       expect \"(yes/no)\"
       send \"yes\r\"
       expect eof"
    done <host
