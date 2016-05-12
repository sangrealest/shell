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
function repSetWithoutPwd(){
#授权slave 所需的用户

    ssh   $MASTER "/usr/local/mysql/bin/mysql  -e \"grant replication slave on *.* to mysqlrepl@'$SLAVE' identified by 'mysqlrepl'\" "

    #开始备份 MASTER 数据库数据
    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 开始备份 $MASTER 数据 \033[0m"
    mkdir -p data
    BAKFILE="data/${MASTER}_`date +'%Y%m%d_%H_%M'`.bak"
    DATABASES=`ssh   $MASTER "/usr/local/mysql/bin/mysql  -N -e 'show databases'|egrep -v 'information_schema|performance_schema'"`
    DATABASES=`echo $DATABASES`
    ssh   $MASTER "/usr/local/mysql/bin/mysqldump -vv -hlocalhost  --skip-opt --create-options --add-drop-table --single-transaction -q -e --set-charset --master-data=2 -K -R --triggers --hex-blob --events  --databases  $DATABASES  " > $BAKFILE
    if [ "$?" -ne 0 ];then
        echo -e "\033[31m\033[05m备份$MASTER数据失败 \033[0m"
        exit
    fi


    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 备份$MASTER数据结束 \033[0m"

    #将master备份数据导入slave数据库
    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 开始导入$MASTER的数据到$SLAVE \033[0m"
    set -o pipefail
    ssh   $SLAVE "$MYSQLBIN/mysql -vvv  -S /tmp/mysql/mysql${PORT}.sock" < $BAKFILE|grep -A 5 INSERT|sed 's/VALUES.*//g'

    if [ "$?" -ne 0 ];then
        echo -e "\033[31m\033[05m导入$MASTER的数据到$SALVE失败 \033[0m"
        exit
    fi

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 导入$MASTER的数据到$SLAVE结束\033[0m"

    LOGPOS=`head -n 30  $BAKFILE|egrep 'CHANGE MASTER' |sed 's/-- CHANGE MASTER TO//g'`
    ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql/mysql${PORT}.sock -e \" stop slave;change master to  master_host='$MASTER', master_user='mysqlrepl',master_password='mysqlrepl', $LOGPOS start slave  \""
    sleep 2
    PNUM=`ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql/mysql${PORT}.sock -e \"show slave status\G \" |egrep \"Slave_IO|Slave_SQL\"|grep 'Yes'|wc -l"`
    LASTERR=`ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql/mysql${PORT}.sock -e 'show slave status\G '"|egrep Error`
    ssh   $SLAVE "$MYSQLBIN/mysql  -S /tmp/mysql/mysql${PORT}.sock -e \"flush privileges\" "

}
function repSetWithPwd(){
   #授权slave 所需的用户
   ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PWD' -e \"grant replication slave on *.* to mysqlrepl@'$SLAVE' identified by 'mysqlrepl'\" "

   #开始备份 MASTER 数据库数据
   echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 开始备份 $MASTER 数据 \033[0m"
   mkdir -p data
   BAKFILE="data/${MASTER}_`date +'%Y%m%d_%H_%M'`.bak"
   DATABASES=`ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PWD' -N -e 'show databases'|egrep -v 'information_schema|performance_schema'"`
   DATABASES=`echo $DATABASES`
   ssh   $MASTER "/usr/local/mysql/bin/mysqldump -uroot -p'$PWD' -vv -hlocalhost  --skip-opt --create-options --add-drop-table --single-transaction -q -e --set-charset --master-data=2 -K -R --triggers --events  --hex-blob   --databases $DATABASES  " > $BAKFILE
   if [ "$?" -ne 0 ];then
       echo -e "\033[31m\033[05m备份$MASTER数据失败 \033[0m"
       exit
   fi


   echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 备份$MASTER数据结束 \033[0m"

   #将master备份数据导入slave数据库
   echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 开始导入$MASTER的数据到$SLAVE \033[0m"
   set -o pipefail
   ssh   $SLAVE "$MYSQLBIN/mysql -vvv -uroot -p'$PWD'  -S /tmp/mysql/mysql${PORT}.sock" < $BAKFILE|grep -A 5 INSERT|sed 's/VALUES.*//g'

   if [ "$?" -ne 0 ];then
       echo -e "\033[31m\033[05m导入$MASTER的数据到$SALVE失败 \033[0m"
       exit
   fi
   echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` 导入$MASTER的数据到$SLAVE结束\033[0m"

   #主从配置
   LOGPOS=`head -n 30  $BAKFILE|egrep 'CHANGE MASTER' |sed 's/-- CHANGE MASTER TO//g'`
   ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PWD' -S /tmp/mysql/mysql${PORT}.sock -e \" stop slave;change master to  master_host='$MASTER', master_user='mysqlrepl',master_password='mysqlrepl', $LOGPOS start slave  \""
   sleep 2
   PNUM=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PWD'  -S /tmp/mysql/mysql${PORT}.sock -e \"show slave status\G \" |egrep \"Slave_IO|Slave_SQL\"|grep 'Yes'|wc -l"`
   LASTERR=`ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PWD' -S /tmp/mysql/mysql${PORT}.sock -e 'show slave status\G '"|egrep Error`
   ssh   $SLAVE "$MYSQLBIN/mysql -uroot -p'$PWD' -S /tmp/mysql/mysql${PORT}.sock -e \"flush privileges\" "


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
            NUM=$OPTARG
            ;;
        p)
            PWD=$OPTARG
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
        echo -e "\033[31m if you use -s, must use -n   \033[0m"
        exit
    fi

    PORT=`expr 3305 + $NUM`
fi



#install mysql to master machine

if [ "$MASTER" != '' -a "$FLAG" -ne 1 ];then

    echo "this is master not null and -f not used"

#    ssh $MASTER '/bin/ps aux|grep mysql|grep  -v grep'
#    if [ $? -eq 0 ]
#    then
#        echo -e "\033[31m  $MASTER mysql already exist  \033[0m"
#        exit 1
#    fi

    echo "mysql not exist in maser"

    ssh   $MASTER "mkdir -p /tmp/mysql"

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` start scp  -r mysqlinstall $MASTER:/tmp/mysql/  \033[0m"

    scp  -r mysqlinstall $MASTER:/tmp/mysql/

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` end scp  -r mysqlinstall $MASTER:/tmp/mysql/  \033[0m"

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` starting install mysql on ${MASTER}  \033[0m"

    ssh   $MASTER "cd /tmp/mysql/mysqlinstall/;sudo sh mysqlinstall.sh -t master -p '$PWD'  "

    if [ "$PWD" == '' ];then
        ssh   $MASTER "/usr/local/mysql/bin/mysql -e '\s'"
        if [ "$?" != 0 ];then
            echo -e "\033[31m \033[05m failed to install \033[0m"
            exit 1
        fi
    else
        ssh   $MASTER "/usr/local/mysql/bin/mysql -uroot -p'$PWD' -e '\s'"
        if [ "$?" != 0 ];then
            echo -e "\033[31m \033[05m failed to install \033[0m"
            exit
        fi
    fi

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` finished install mysql on ${MASTER} \033[0m"


fi


#install mysql to slave machine

if [ "$SLAVE" != '' -a "$FLAG" -ne 1 ];then

    ssh   $SLAVE "/usr/bin/lsof -i:$PORT"
#    if [ $? -eq 0 ]
#    then
#        echo -e "\033[31m  ${SLAVE}:${PORT} mysql database already exist  \033[0m"
#        exit
#    fi

    ssh   $SLAVE "mkdir -p /tmp/mysql${PORT}"

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` start scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/  \033[0m"
    scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/
    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` end scp  -r mysqlinstall $SLAVE:/tmp/mysql${PORT}/  \033[0m"

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` starting to install mysql on ${SLAVE}  \033[0m"
    ssh   $SLAVE "cd /tmp/mysql${PORT}/mysqlinstall/;sudo sh mysqlinstall.sh -t slave -n $NUM -p '$PWD'"

    if [ "$PWD" == '' ];then
        ssh   $SLAVE "/usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql/mysql${PORT}.sock -e '\s'"
        if [ "$?" -ne 0 ];then
            echo -e "\033[31m \033[05m failed to install mysql \033[0m"
            exit
        fi
    else
        ssh   $SLAVE "/usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql/mysql${PORT}.sock -uroot -p'$PWD' -e '\s'"
        if [ "$?" -ne 0 ];then
            echo -e "\033[31m \033[05m failed to install mysql \033[0m"
            exit
        fi
    fi

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` finished to install mysql on ${SLAVE}  \033[0m"

fi

#configure master-slave

if [ "$SLAVE" != '' -a "$MASTER" != '' -a "$FLAG" -eq 1 ];then

#    MASTER=`/bin/ping $MASTER -c 1  |grep "PING"| awk -F ') ' '{print $1}'|awk -F "(" '{print $2}' |head -n 1`
#    SLAVE=`/bin/ping $SLAVE -c 1  |grep "PING"| awk -F ') ' '{print $1}'|awk -F "(" '{print $2}' |head -n 1`
    MYSQLBIN="/usr/local/mysql${PORT}/bin"
    echo -e "\033[31m## $(date +"%Y-%m-%d %H:%M:%S") 开始 $MASTER ${SLAVE} 主从复制配置  \033[0m"
    if [ "$PWD" == '' ];then
        repSetWithoutPwd
    
    else

        repSetWithPwd
    fi
    
    if [ "$PNUM" -eq 2 ];then
        echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE 主从复制成功 \033[0m"
        test -f $BAKFILE && rm -rf $BAKFILE
    else
        echo -e "\033[31m\033[05m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE 主从复制失败 \033[0m"
        echo $LASTERR
        test -f $BAKFILE && rm -rf $BAKFILE
        exit
    fi

    echo -e "\033[31m##`date +"%Y-%m-%d %H:%M:%S"` $MASTER $SLAVE 主从复制配置结束 \033[0m"
fi
