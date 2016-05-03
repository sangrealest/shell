#!/bin/bash
#author:shanker
#date:2012/03/13
function softinstall(){
        if [ -s /usr/bin/rsync -o -s /usr/local/bin/rsync ]
        then
                echo "you had installed rsync, exiting now"
                exit 1
        fi
        if [ -s rsync-3.0.9.tar.gz ]
        then
                echo "rsync-3.0.9.tar.gz file found"
                tar zxvf rsync-3.0.9.tar.gz
                cd rsync-3.0.9
                ./configure
                make && make install
        else
                echo "no rsync found, exit"
                exit 1
        fi
}
function configurefile(){
useradd shanker
touch /etc/rsyncd.conf
touch /etc/web.pass
chmod 600 /etc/web.pass
cat >/etc/rsyncd/rsyncd.conf <<EOF
# Distributed under the terms of the GNU General Public License v2
# Minimal configuration file for rsync daemon
# See rsync(1) and rsyncd.conf(5) man pages for help

# This line is required by the /etc/init.d/rsyncd script
gid = nobody
gid = nobody
use chroot = no
max connections = 10
strict modes = yes
pid file = /var/run/rsyncd.pid
lock file = /var/run/rsyncd.lock
log file = /var/run/rsyncd.log
[web]
path = /opt/web/
comment = nagios document
ignore errors
read only = no
write only = no
hosts allow = 192.168.0.1/24 10.0.0.1/24
hosts deny = *
list = false
uid = root
gid = root
auth users = shanker
secrets file = /etc/web.pass
EOF
echo "shanker:123">/etc/web.pass
}
function configureserverfile(){
        echo "123">/etc/server.pass
}
cat <<EOF
"welcome to install rsync 3.0.9"
1.server install model(the current is your rsync server)
2.client install model(the current is your rsync client)
Please choose one
EOF
read choice
case $choice in
1)
        echo "you chose to install rsync in your server"
        softinstall &&  configureserverfile;;
2)
        ehcho "you chose to install rsync in your clients"
        softinstall &&  configurefile;;
*)
        echo "bad choise"
        ./installrsync.sh;;
esac
