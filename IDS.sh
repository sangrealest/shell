#!/bin/bash
#intruder_detect
#detect the invlaid users
AUTHLOG=/var/log/syslog
if [ -n "$1" ]
then
  AUTHLOG=$1
    echo "Using log file:$AUTHLOG"
    fi
    LOG=/tmp/valid.$$.log
    grep -vi "invalid" "$AUTHLOG" > $LOG
    users=$(grep "Failed password" $LOG | awk '{print $(NF - 5)}'|sort -u)
    printf "%-5s|%-10s|%-10s|%-13s|%-33s|%s\n"  "Sr#" "User" "Attempts" "IP address" "Host_mapping" "Time Range"
    ucount=0
    ip_list="$(egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" $LOG |sort -u)"
    for ip in $ip_list
    do
      grep $ip $LOG > /tmp/temp.$$.log
        for user in $users
          do
              grep $user /tmp/temp.$$.log > /tmp/$$.log
                  cut -c-16 /tmp/$$.log > /tmp/$$.time
                      tstart=$(head -1 /tmp/$$.time)
        start=$(date -d "$tstart" "+%s")
            tend=$(tail -1 /tmp/$$.time)
        end=$(date -d "$tend" "+%s")
            limit=$(($end - $start))
        if [ $limit -gt 20 ]
            then
                  let ucount++
                        IP=$(egrep -o  "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" /tmp/$$.log|head -1)
                              TIME_RANGE="$tstart--->$tend"
                                    ATTEMPTS=$(cat /tmp/$$.log|wc -l)
          HOST=$(host $IP |awk '{print $NF}')
                printf "%-5s|%-10s|%-10s|%-13s|%-33s|%s\n" "$ucount" "$user" "$ATTEMPTS" "$IP" "$HOST" "$TIME_RANGE"
                    fi
                        done
                        done
                        rm /tmp/valid.$$.log /tmp/$$.log /tmp/$$.time /tmp/temp.$$.log 2>/dev/null
                              
