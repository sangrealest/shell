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


NUM=''
PORT=''

function limitsConf(){
sed -i "/nproc/d"  /etc/security/limits.conf
sed -i "/nofile/d"  /etc/security/limits.conf
echo "*        soft    nproc           65535" >> /etc/security/limits.conf
echo "*        hard    nproc           65535" >> /etc/security/limits.conf
echo "*        soft    nofile           65535" >> /etc/security/limits.conf
echo "*        hard    nofile           65535" >> /etc/security/limits.conf

if [ -f /etc/security/limits.d/90-nproc.conf ]
then
  sed -i "/nproc/d"  /etc/security/limits.d/90-nproc.conf
  echo "*        soft    nproc           65535" >> /etc/security/limits.d/90-nproc.conf
  echo "*        hard    nproc           65535" >> /etc/security/limits.d/90-nproc.conf
fi
}

function setConf(){

sed  -i  "/\/usr\/local\/mysql${PORT}\/bin/"d /etc/profile
echo "export PATH=/usr/local/mysql${PORT}/bin:\$PATH ">>/etc/profile
sudo /sbin/sysctl -p

cp -a  mysql.server /etc/init.d/mysqld${PORT}

sed -i "s#/usr/local/mysql#/usr/local/mysql${PORT}#" /etc/init.d/mysqld${PORT}

sed -i "s#/data/mysql/mysqldata/data#/data/mysql${PORT}/mysqldata/data#" /etc/init.d/mysqld${PORT}

}

function startMysql(){

chmod +x /etc/init.d/mysqld${PORT}
/sbin/chkconfig --add mysqld${PORT}
/sbin/chkconfig mysqld${PORT} on
/etc/init.d/mysqld${PORT} start

}

function secureMysql(){

if [ "$TYPE" == 'slave' ];then
    mysqldir=/usr/local/mysql${PORT}/bin
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock   -e "delete from mysql.user where user='';"
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock    -e "delete from mysql.user where host='';"
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock    -e "grant all on *.* to root@'127.0.0.1' identified by '$PWD'"
    $mysqldir/mysqladmin -S /tmp/mysql${PORT}.sock    password  $PWD

    if [ "$PWD" == '' ];then
        /usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock -e "use mysql"
        FLAG=$?
    else
        /usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock  -uroot -p$PWD  -e "use mysql"
        FLAG=$?
    fi

else
    mysqldir=/usr/local/mysql/bin
    $mysqldir/mysql  -e "delete from mysql.user where user='';"
    $mysqldir/mysql  -e "delete from mysql.user where host='';"
    $mysqldir/mysql  -e "grant all on *.* to root@'127.0.0.1' identified by '$PWD'"
    $mysqldir/mysqladmin  password  $PWD

    if [ "$PWD" == '' ];then
        /usr/local/mysql${PORT}/bin/mysql   -e "use mysql"
        FLAG=$?
    else
        /usr/local/mysql${PORT}/bin/mysql  -uroot -p$PWD  -e "use mysql"
        FLAG=$?
    fi

fi
}

while getopts ":t:n:p:t:h" opts
do
    case $opts in
        h)
            usage
            ;;
        t)
            TYPE=$OPTARG
            if ! [ "$TYPE" == 'master'  -o "$TYPE" == 'slave' ]
            then
                usage
            fi
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

if [[ $NUM != '' ]];then
    PORT=`expr 3305 + $NUM`
fi


#before install mysql, clear potential folders
rm -rf /etc/init.d/mysql${PORT}
rm -rf /data/mysql${PORT}
rm -rf /usr/local/mysql${PORT}

grep mysql /etc/passwd >/dev/null

if [ "$?" -ne 0 ]
then
    useradd mysql
fi

if [ ! -d /usr/loal/mysql${PORT} ];then
        mkdir /usr/local/mysql${PORT}
fi

for i in redolog slowquery binlog relaylog
do
    mkdir -p /data/mysql${PORT}/mysqllog/$i
done
for j in data ibdata
do
    mkdir -p /data/mysql${PORT}/mysqldata/$j
done


MYSQLFILE=$(ls |grep *.tar.gz)
MYSQLDIR=$(echo $MYSQLFILE|sed 's/.tar.gz//')

if [ ! -d "$MYSQLDIR" ];then
        tar xvf $MYSQLFILE
fi
mv -f $MYSQLDIR/* /usr/local/mysql${PORT}
rm -rf $MYSQLDIR

chown -R mysql:mysql /usr/local/mysql${PORT}
chown -R mysql:mysql /data/mysql${PORT}

FREEMEM1=$(awk 'NR==1{print int($2/1024*0.2)}' /proc/meminfo)
INNODB_BUTTER_POOL_SIZE_SLAVE=$(echo $FREEMEM1|awk '{if($1 > 1024) {printf "%d%s" ,int($1/1024),"G" } else {printf "%d%s",($1),"M"} }')

FREEMEM2=$(awk 'NR==1{print int($2/1024*0.2)}' /proc/meminfo)
INNODB_BUTTER_POOL_SIZE_MASTER=$(echo $FREEMEM2|awk '{if($1 > 1024) {printf "%d%s" ,int($1/1024),"G" } else {printf "%d%s",($1),"M"} }')



if [ "$TYPE" == 'slave' ]
then
    cp -a myconfile /usr/local/mysql${PORT}/my.cnf
    sed -i '/^server-id/ c server-id = 2' /usr/local/mysql${PORT}/my.cnf
    sed -i "s#/data/mysql/#/data/mysql${PORT}/#" /usr/local/mysql${PORT}/my.cnf
    sed -i "/^socket/ c socket     = /tmp/mysql${PORT}.sock" /usr/local/mysql${PORT}/my.cnf
    sed -i "/^port/ c port =  ${PORT}"  /usr/local/mysql${PORT}/my.cnf
    sed -i "/^innodb_buffer_pool_size/ c innodb_buffer_pool_size = ${INNODB_BUTTER_POOL_SIZE_SLAVE}" /usr/local/mysql${PORT}/my.cnf

    setConf
else
    cp -a myconfile /etc/my.cnf
    sed -i -i "/^innodb_buffer_pool_size/ c innodb_buffer_pool_size = ${INNODB_BUTTER_POOL_SIZE_MASTER}" /etc/my.cnf
    setConf

fi

/usr/local/mysql${PORT}/scripts/mysql_install_db  --basedir=/usr/local/mysql${PORT} --datadir=/data/mysql${PORT}/mysqldata/data  --user=mysql

limitsConf

startMysql

secureMysql

if [ "$FLAG" -eq 0  ]
then
    echo -e "\033[31m  数据库安装完毕 \033[0m"
    echo -e "\033[32m 1、安装脚本已经将mysql设为系统的自启动服务器 \033[0m"
    echo -e "\033[32m 2、mysql服务管理工具使用方法：/etc/init.d/mysqld${PORT}  {start|stop|restart|reload|force-reload|status}  \033[0m"
    echo -e "\033[32m 3、mysql命令的全路径: /usr/local/mysql${PORT}/bin/mysql  \033[0m"
    echo -e "\033[32m 4、重开一个session，可使用mysql -S  /tmp/mysql${PORT}.sock  -uroot -p 进入mysql。  \033[0m"
    echo -e "\033[32m 5、数据库的root密码: $PWD  \033[0m"
else
    echo -e "\033[31m \033[05m 数据库安装失败 \033[0m"
    exit 1
fi
