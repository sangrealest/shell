#!/bin/bash
#Author:Shanker
#Time:20160511

#set -e
#set -x
#set -u

function usage(){
    cat <<EOF

usage:$0 [options] [pattern]
    -h  Help;
    -m  Master hostname or ip address;
    -s  Slave hostname or ip address;
    -n  Configure how many instances, if the port is 3306, n should be 1, port is 3307, n shoule be 2 and so on..;
    -p  Password to access your database;
    -f  Do not install mysql, only configre master-slave;
EOF
exit
}

function repSetWithoutPSWD(){

    ssh   $MASTER "/usr/local/mysql/bin/mysql  -e \"GRANT REPLICATION slave on *.* to mysqlrepl@'$SLAVE' identified by 'mysqlrepl' WITH GRANT OPTION\" "

    #start to backup database of MASTER
    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` start to backup $MASTER  data \033[0m"
    mkdir -p data
    BAKFILE="data/${MASTER}_`date +'%Y%m%d_%H_%M'`.bak"
    DATABASES=`ssh   $MASTER "/usr/local/mysql/bin/mysql  -N -e 'show databases'|egrep -v 'information_schema|performance_schema'"`
    DATABASES=`echo $DATABASES`
    ssh   $MASTER "/usr/local/mysql/bin/mysqldump -vv -hlocalhost  --skip-opt --create-options --add-drop-table --single-transaction -q -e --set-charset --master-data=2 -K -R --triggers --hex-blob --events  --databases  $DATABASES  " > $BAKFILE
    if [ "$?" -ne 0 ];then
        echo -e "\033[32m\033[05m backup $MASTER data failed  \033[0m"
        exit
    fi


    echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  backup $MASTER data finished \033[0m"

    #import master's database to slave 
    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"`  start imoprt $MASTER's data to $SLAVE \033[0m"
    set -o pipefail
    ssh   $SLAVE "$MYSQLBIN/mysql -vvv  -S /tmp/mysql${PORT}.sock" < $BAKFILE|grep -A 5 INSERT|sed 's/VALUES.*//g'

    if [ "$?" -ne 0 ];then
        echo -e "\033[32m\033[05m import $MASTER's data to $SALVE failed  \033[0m"
        exit
    fi

    echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  import $MASTER's data to $SLAVE finished \033[0m"

    LOGPOS=`head -n 30  $BAKFILE|egrep 'CHANGE MASTER' |sed 's/-- CHANGE MASTER TO//g'`
    ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql${PORT}.sock -e \" stop slave;change master to  MASTER_HOST='$MASTER', MASTER_USER='mysqlrepl', MASTER_PASSWORD='mysqlrepl', $LOGPOS start slave  \""
    sleep 2
    PNUM=`ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql${PORT}.sock -e \"show slave status\G \" |egrep \"Slave_IO|Slave_SQL\"|grep 'Yes'|wc -l"`
    LASTERR=`ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql${PORT}.sock -e 'show slave status\G '"|egrep Error`
    ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql${PORT}.sock -e \"flush privileges\" "

}
function repSetWithPSWD(){

   ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PSWD' -e \"GRANT REPLICATION slave on *.* to mysqlrepl@'$SLAVE' identified by 'mysqlrepl' WITH GRANT OPTION\" "

   #start to backup MASTER  database  data
   echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` start to backup $MASTER  data \033[0m"
   mkdir -p data
   BAKFILE="data/${MASTER}_`date +'%Y%m%d_%H_%M'`.bak"
   DATABASES=`ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PSWD' -N -e 'show databases'|egrep -v 'information_schema|performance_schema'"`
   DATABASES=`echo $DATABASES`
   ssh   $MASTER "/usr/local/mysql/bin/mysqldump -uroot -p'$PSWD' -vv -hlocalhost  --skip-opt --create-options --add-drop-table --single-transaction -q -e --set-charset --master-data=2 -K -R --triggers --events  --hex-blob   --databases $DATABASES  " > $BAKFILE
   if [ "$?" -ne 0 ];then
       echo -e "\033[32m\033[05m backup $MASTER data failed  \033[0m"
       exit
   fi


   echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  backup $MASTER data finished  \033[0m"

   #import master's data to slave database 
   echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"`  start  import $MASTER data to $SLAVE \033[0m"
   set -o pipefail
   ssh   $SLAVE "$MYSQLBIN/mysql -vvv -uroot -p'$PSWD'  -S /tmp/mysql${PORT}.sock" < $BAKFILE|grep -A 5 INSERT|sed 's/VALUES.*//g'

   if [ "$?" -ne 0 ];then
        echo -e "\033[32m\033[05m import $MASTER's data to $SALVE failed  \033[0m"
        exit
   fi

   echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"`  import $MASTER's data to $SLAVE finished \033[0m"
   #Master-Slave Replication
   LOGPOS=`head -n 30  $BAKFILE|egrep 'CHANGE MASTER' |sed 's/-- CHANGE MASTER TO//g'`
   ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -S /tmp/mysql${PORT}.sock -e \" stop slave;change master to  MASTER_HOST='$MASTER', MASTER_USER='mysqlrepl', MASTER_PASSWORD='mysqlrepl', $LOGPOS start slave  \""
   sleep 2
   PNUM=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD'  -S /tmp/mysql${PORT}.sock -e \"show slave status\G \" |egrep \"Slave_IO|Slave_SQL\"|grep 'Yes'|wc -l"`
   LASTERR=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -S /tmp/mysql${PORT}.sock -e 'show slave status\G '"|egrep Error`
   ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PSWD' -S /tmp/mysql${PORT}.sock -e \"flush privileges\" "


}


MASTER=''
SLAVE=''
NUM=''
FLAG=0
TYPE=''

while getopts ":m:s:p:n:t:fkh" opts
do
    case $opts in
        h)
            usage
            ;;
        m)
            MASTER=$OPTARG
            ;;
        s)
            SLAVE=$OPTARG
            ;;
        f)
            FLAG=1
            ;;
        n)
            NUM=$OPTARG ;;
        p)
            PSWD=$OPTARG
            ;;
        :)
            echo "No argument value for option $OPTARG"
            ;;
        *)
            echo "Unknow error while processing options"
            -$OPTARG unvalid
            usage
            ;;
    esac
done

if [ "$SLAVE" != ''  ];then
    if [ "$NUM" == '' ];then
        echo -e "\033[32m if you use -s, must use -n   \033[0m"
        exit
    fi

    PORT=`expr 3305 + $NUM`
fi



#install mysql to master machine

if [ "$MASTER" != '' -a "$FLAG" -ne 1 ];then

    echo "this is master not null and -f not used"

    ssh $MASTER '/bin/ps aux|grep mysqld|grep  -v grep'
    if [ $? -eq 0 ]
    then
        echo -e "\033[32m  $MASTER mysql already exist  \033[0m"
        exit 1
    fi

    echo "mysql not exist in maser"

    ssh   $MASTER "mkdir -p /tmp/mysql"

    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` start scp  -r mysqlinstall $MASTER:/tmp/mysql/  \033[0m"

    scp  -r mysqlinstall $MASTER:/tmp/mysql/

    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` end scp  -r mysqlinstall $MASTER:/tmp/mysql/  \033[0m"

    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` starting install mysql on ${MASTER}  \033[0m"

    ssh   $MASTER "cd /tmp/mysql/mysqlinstall/;sh mysqlinstall.sh -t master -p $PSWD "

    if [ "$PSWD" == '' ];then
        ssh   $MASTER "/usr/local/mysql/bin/mysql -e '\s'"
        if [ "$?" != 0 ];then
            echo -e "\033[32m \033[05m failed to install \033[0m"
            exit 1
        fi
    else
        ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PSWD' -e '\s'"
        if [ "$?" != 0 ];then
            echo -e "\033[32m \033[05m failed to install \033[0m"
            exit
        fi
    fi

    echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"` finished install mysql on ${MASTER} \033[0m"


fi


#install mysql to slave machine

if [ "$SLAVE" != '' -a "$FLAG" -ne 1 ];then


    ssh   $SLAVE "/usr/sbin/lsof -i:$PORT"
    if [ $? -eq 0 ]
    then
        echo -e "\033[32m  ${SLAVE}:${PORT} mysql database already exist  \033[0m"
        exit
    fi

    ssh   $SLAVE "mkdir -p /tmp/mysql${PORT}"

    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` start scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/  \033[0m"
    scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/
    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` end scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/  \033[0m"

    echo -e "\033[32m##`date +"%Y-%m-%d %H:%M:%S"` starting to install mysql on ${SLAVE}  \033[0m"
    echo "the numer is $NUM------------------------------------------------------------------------------"
    ssh   $SLAVE "cd /tmp/mysql${PORT}/mysqlinstall/;sh mysqlinstall.sh -t slave -n $NUM -p $PSWD"

    if [ "$PSWD" == '' ];then
        ssh   $SLAVE "/usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock -e '\s'"
        if [ "$?" -ne 0 ];then
            echo -e "\033[32m \033[05m failed to install mysql \033[0m"
            exit
        fi
    else
        ssh   $SLAVE "/usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock -uroot -p'$PSWD' -e '\s'"
        if [ "$?" -ne 0 ];then
            echo -e "\033[32m \033[05m failed to install mysql \033[0m"
            exit
        fi
    fi

    echo -e "\033[35m##`date +"%Y-%m-%d %H:%M:%S"` finished to install mysql on ${SLAVE}  \033[0m"

fi

#configure master-slave

if [ "$SLAVE" != '' -a "$MASTER" != '' -a "$FLAG" -eq 1 ];then

#must use ip address to grant replication;
#get master and slave ip address

    MASTER=`/bin/ping $MASTER -c 1  |grep "PING"| awk -F ') ' '{print $1}'|awk -F "(" '{print $2}' |head -n 1`
    SLAVE=`/bin/ping $SLAVE -c 1  |grep "PING"| awk -F ') ' '{print $1}'|awk -F "(" '{print $2}' |head -n 1`
    MYSQLBIN="/usr/local/mysql${PORT}/bin"
    echo -e "\033[32m## $(date +"%Y-%m-%d %H:%M:%S")  start  $MASTER ${SLAVE} Master_Slave Replication \033[0m"
    if [ "$PSWD" == '' ];then

        repSetWithoutPSWD
    
    else

        repSetWithPSWD
    fi
    
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
fi
