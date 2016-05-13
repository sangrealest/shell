#!/bin/bash
# NAME            nagios_intall.sh
#Author:Shanker
#Date:2013/9/


yum install httpd php -y
yum install gcc glibc glibc-common -y
yum install gd gd-devel -y
/usr/sbin/useradd -m nagios
/usr/sbin/groupadd nagcmd
/usr/sbin/usermod -a -G nagcmd nagios
/usr/sbin/usermod -a -G nagcmd apache
mkdir -p /opt/nagios_install_packages
cd /opt/nagios_install_packages
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.2.3.tar.gz
wget http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.11.tar.gz
wget http://sourceforge.net/projects/nagios/files/nrpe-2.x/nrpe-2.12/nrpe-2.12.tar.gz
# nagios
tar -xzf nagios-3.2.3.tar.gz
cd nagios-3.2.3
./configure --with-command-group=nagcmd
make all
make install
make install-init
make install-config
make install-commandmode
make install-webconf
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
service httpd restart
cd /opt
# plugins
tar -xzf nagios-plugins-1.4.11.tar.gz
cd nagios-plugins-1.4.11
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make
make install
chkconfig --add nagios
chkconfig nagios on
service nagios start
cd /opt
# nrpe
tar -xzf nrpe-2.12.tar.gz
cd nrpe-2.12
./configure --with-nagios-user=nagios --with-nagios-group=nagios
make all
make install-plugin

