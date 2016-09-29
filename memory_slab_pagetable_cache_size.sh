#/bin/bash
for PROC in `ls /proc/|grep "^[0-9]"`
do
  if [ -f /proc/$PROC/statm ]; then
      TEP=`cat /proc/$PROC/statm | awk '{print ($2)}'`
      RSS=`expr $RSS + $TEP`
  fi
done
RSS=`expr $RSS \* 4`
PageTable=`grep PageTables /proc/meminfo | awk '{print $2}'`
SlabInfo=`cat /proc/slabinfo |awk 'BEGIN{sum=0;}{sum=sum+$3*$4;}END{print sum/1024/1024}'`
 
echo $RSS"KB", $PageTable"KB", $SlabInfo"MB"
printf "rss+pagetable+slabinfo=%sMB\n" `echo $RSS/1024 + $PageTable/1024 + $SlabInfo|bc`
free -m

