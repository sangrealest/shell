#!/bin/bash
#Author:Shanker
set -x
#set -u
#must use ip address to do replication
#Configure your slave server yourself
#Make sure your slave use the same password as master which you put herer PSWD

while getopts ":m:s:ph" opts
do
    case $opts in
        h)
            echo "Input -m master ip address"
            echo "Input -s slave ip address"
            echo " Input -p password of your mysql"
            ;;
        m)
            MASTER=$OPTARG
            ;;
        s)
            SLAVE=$OPTARG
            ;;
        p)
            PSWD=$OPTARG
            ;;
        *)
            -$OPTARG unvalid
            exit 2
            ;;
    esac
done

MYSQLBIN="/usr/bin"
ssh $MASTER "/usr/bin/mysql -uroot -p'$PSWD' -e \"GRANT REPLICATION slave on *.* to mysqlrepl@'$SLAVE' identified by 'mysqlrepl' WITH GRANT OPTION\" "

#start to backup MASTER  database  data
echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` start to backup $MASTER  data \033[0m"
mkdir -p data
BAKFILE="data/${MASTER}_`date +'%Y%m%d_%H_%M'`.bak"
DATABASES=`ssh   $MASTER "/usr/bin/mysql -uroot -p'$PSWD' -N -e 'show databases'|egrep -v 'information_schema|performance_schema'"`
DATABASES=`echo $DATABASES`
ssh   $MASTER "/usr/bin/mysqldump -uroot -p'$PSWD' -vv -hlocalhost  --skip-opt --create-options --add-drop-table --single-transaction -q -e --set-charset --master-data=2 -K -R --triggers --events  --hex-blob   --databases $DATABASES  " > $BAKFILE
if [ "$?" -ne 0 ];then
    echo -e "\033[32m\033[05m backup $MASTER data failed  \033[0m"
    exit
fi


echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  backup $MASTER data finished  \033[0m"

#import master's data to slave database

echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"`  start  import $MASTER data to $SLAVE \033[0m"
set -o pipefail
ssh   $SLAVE "$MYSQLBIN/mysql -vvv -uroot -p'$PSWD' " < $BAKFILE|grep -A 5 INSERT|sed 's/VALUES.*//g'

if [ "$?" -ne 0 ];then
     echo -e "\033[32m\033[05m import $MASTER's data to $SALVE failed  \033[0m"
     exit
fi

echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  import $MASTER's data to $SLAVE finished \033[0m"

#Master-Slave Replication

LOGPOS=`head -n 30  $BAKFILE|egrep 'CHANGE MASTER' |sed 's/-- CHANGE MASTER TO//g'`
ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -e \" stop slave;change master to  MASTER_HOST='$MASTER', MASTER_USER='mysqlrepl', MASTER_PASSWORD='mysqlrepl', $LOGPOS start slave  \""

sleep 2
PNUM=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD'  -e \"show slave status\G \" |egrep \"Slave_IO|Slave_SQL\"|grep 'Yes'|wc -l"`
LASTERR=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -e 'show slave status\G '"|egrep Error`

ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -e \"flush privileges\" "

if [ "$PNUM" -eq 2 ];then
    echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE replication successfully \033[0m"
    if [ -f $BAKFILE ];then
        rm -rf $BAKFILE
    fi
else
    echo -e "\033[31m\033[05m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE replication failed  \033[0m"
    echo $LASTERR
    if [ -f $BAKFILE ];then
        rm -rf $BAKFILE
    fi
    exit
fi

echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE Master Slave Replication finished  \033[0m"

