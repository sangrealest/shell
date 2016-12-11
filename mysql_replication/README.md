# mysql
Author:Shanker

Mysql Master Slave Replication
This is an auto shell script to set up Mysql Master Slave Repliations. You could install multi masters and multi slaves on different machines. or install multi slaves on one machines with different masters.

Tested in CentOS Release 6.7 (final) 2.6.32-573.12.1.el6.x86_64

In master, the default port is 3306, but in slave, it depends on the number followed by -n, if -n is 1, then port is 3306, -2 is 3307 and so on.

Before run this script, be sure you are using root and could ssh to your servers with ssh-key.

MySQL Version: mysql-5.5.39-linux2.6-x86_64.tar.gz, download it form here:
https://downloads.mysql.com/archives/get/file/mysql-5.5.39-linux2.6-x86_64.tar.gz

Examples:


init_mysql.sh -m databse1 -s backup -n 1 -p'pwd'
init_mysql.sh -m databse2 -s backup -n 2 -p'pwd'
init_mysql.sh -m databse3 -s backup -n 3 -p'pwd'

If you want to configure replication, use -f

init_mysql.sh -m databse1 -s backup -n 1 -p'pwd' -f

If you only want to install database, just use -m or -s

    -h  Help;
    -m  Master hostname or ip address;
    -s  Slave hostname or ip address;
    -n  Configure how many instances, if the port is 3306, n should be 1, port is 3307, n shoule be 2 and so on..;
    -p  Password to access your database;
    -f  Do not install mysql, only configre master-slave;

