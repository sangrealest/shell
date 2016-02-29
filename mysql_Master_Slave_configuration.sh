#!/bin/bash
#author:shanker
#date:2012/4/12
#Mysql master slave replication
menu(){
    echo
        echo
        currentdate=$(date "+%Y-%m-%d %T")
        cat<<EOF
        DATE:$currentdate
        ===============================
        1)install software
        2)configure the master
        3)ocnfigure the slave
        4)exit
        ===============================
        EOF
}

function install(){
    if [ $UID ! -eq 0 ]
        then
                 echo "you are not root, exit now"
                      exit 1
                      fi
                      grep -q mysql /etc/passwd
                      if [ $? -eq 0 ]
                          then
                              grep -q mysql /etc/group
                              if [ $? ! -eq 0 ]
                                  then
                                       useradd -g mysql mysql
                              fi
                          echo "mysql user and group had exist!"
                       else
                            grep -q mysql /etc/group
                            if [ $? ! -eq 0 ]
                                then
                                       groupadd mysql
                                       useradd -g mysql mysql
                            fi
                        groupadd mysql
                        fi

               if [ -s mysql-5.1.45.tar.gz ]
                   then
                        echo "mysql-5.1.45.tar.gz file found"
                        tar zxvf mysql-5.1.45.tar.gz
                        cd mysql-5.1.45
                       ./configure --prefix=/usr/local/mysql --enable-local-infile\
                       --with-charset=utf8  --with-extra-charsets=all --enable-thread-safe-client\
                       --enable-assembler --with-unix-socket-path=/usr/local/mysql/tmp/mysql.sock\
                       --with-plugins=innobase
                       make && make install
                       else
                       echo "no mysql found, exit"
                       exit 1
                       fi
                       cp support-files/my-medium.cnf /etc/my.cnf
                       sed -i 's/skip-locking/skip-external-locking/' /etc/etc.my.cnf
                       cd /usr/local/mysql
                       bin/mysql_install_db --user=mysql
                       mkdir tmp
                       chown -R root  .
                       chown -R mysql var
                       chown -R mysql tmp
                       chgrp -R mysql .
                       bin/mysqld_safe --user=mysql &

function configmaster(){
cat >/etc/my.cnf<<EOF
[client]
port          = 3306
socket          = /tmp/mysql.sock
[mysqld]
port          = 3306
socket          = /tmp/mysql.sock
skip-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
log-bin=mysql-bin
binlog_format=mixed
server-id     = 1
[mysqldump]
quick
max_allowed_packet = 16M
[mysql]
no-auto-rehash
[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M
[mysqlhotcopy]
interactive-timeout
EOF
}

function configslave(){
cat >/etc/my.cnf<<EOF
[client]
port          = 3306
socket          = /usr/local/mysql/tmp/mysql.sock
[mysqld]
port          = 3306
socket          = /usr/local/mysql/tmp/mysql.sock
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
table_open_cache = 64
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
server-id=2
master-host=192.168.0.225
master-user=shanker
master-password=1234
master-port=3306
master-connect-retry=60
replicate-do-db=testdba
log-bin=mysql-bin
binlog_format=mixed
[mysqldump]
quick
max_allowed_packet = 16M
[mysql]
no-auto-rehash
[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M
[mysqlhotcopy]
interactive-timeout
server-id=1
log-bin=/var/mysql/mysqllog
binlog-do-db=testdb
read-only=0
binlog-ignore-db=mysql
EOF

}
while :
do
menu
echo -n " Please choose [1-7]:"
read choose
case $choose in
1)install;;
2)configmaster;;
3)configslave;;
4)exit ;;
*)
clear
continue;;
esac
done

