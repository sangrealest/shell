#!/bin/bash
clear
echo "内网卡上千M总数:";/usr/sbin/rshrun -la /sbin/ethtool eth0|awk '/Speed/ {print}'|grep 1000M|wc -l
echo "外网卡上千M总数:";/usr/sbin/rshrun -lg=game,link,delivery,backup /sbin/ethtool eth1|awk '/Speed/ {print}'|grep 1000M|wc -l
echo "-----------------------------------------------------------"
echo "检查系统内核版本是否为64位版本";/bin/uname -r;rshrun -la "/bin/uname -r"
echo "-----------------------------------------------------------"
echo "Manager 分区情况:";/bin/cat /proc/partitions;/bin/df -h
echo "-----------------------------------------------------------"
echo "Database 分区情况:";/usr/bin/rsh database /bin/cat /proc/partitions;/usr/bin/rsh database /bin/df -h
echo "-----------------------------------------------------------"
echo "Backup 分区情况:";/usr/bin/rsh backup /bin/cat /proc/partitions;/usr/bin/rsh backup /bin/df -h
echo "-----------------------------------------------------------"
echo "检查manager磁盘错误信息";/root/MegaCli -PDlist -aALL |grep Error
echo "-----------------------------------------------------------"
echo "检查game1磁盘错误信息";/usr/bin/rsh game1 /root/MegaCli -PDlist -aALL |grep Error
echo "-----------------------------------------------------------"
echo "检查database磁盘错误信息";/usr/bin/rsh database /root/MegaCli -PDlist -aALL |grep Error
echo "-----------------------------------------------------------"
echo "检查backup磁盘错误信息";/usr/bin/rsh backup /root/MegaCli -PDlist -aALL |grep Error
echo "-----------------------------------------------------------"
echo "Manager FW Version:";/root/MegaCli -AdpAllInfo -aALL|grep FW
echo "-----------------------------------------------------------"
echo "Database FW Version:";/usr/bin/rsh database /root/MegaCli -AdpAllInfo -aALL|grep FW
echo "-----------------------------------------------------------"
echo "Backup FW Version:";/usr/bin/rsh backup /root/MegaCli -AdpAllInfo -aALL|grep FW
echo "-----------------------------------------------------------"
echo "检查内存:";/usr/sbin/rshrun -la "free -m"
echo "-----------------------------------------------------------"
echo "/export/web/属性权限:";/bin/ls -l /export/|grep web
echo "/home/web/属性权限:";/bin/ls -l /home/|grep web
echo "-----------------------------------------------------------"
md5sum /home/web/.ssh/authorized_keys
a="8b4091d13172a2f619b419782f0cfbb4"
b="`md5sum /home/web/.ssh/authorized_keys|awk '{print $1}'`"
if [ "$a" == "$b" ]
then
echo "/home/web/.ssh/authorized_keys 已经是最新的"
else
echo "authorized_keys 错误"
fi
echo "-----------------------------------------------------------"
md5sum /home/log/.ssh/authorized_keys
c="6547b4802a828efb52cdad11a080014f"
d="`md5sum /home/log/.ssh/authorized_keys|awk '{print $1}'`"
if [ "$c" == "$d" ]
then
echo "/home/log/.ssh/authorized_keys 已经是最新的"
else
echo "authorized_keys 错误"
fi
echo "-----------------------------------------------------------"
echo "检查用户是否创建";/usr/bin/id wl_log
echo "-----------------------------------------------------------"
echo "/etc/hosts文件是否更新";/bin/cat /etc/hosts
echo "/export/game1/etc/hosts是否更新";/bin/cat /export/game1/etc/hosts
echo "/export/database/etc/hosts是否更新";/bin/cat /export/database/etc/hosts
echo "/export/backup/etc/hosts是否更新";/bin/cat /export/backup/etc/hosts
echo "-----------------------------------------------------------"
echo "检查MonitorV3是否安装";/bin/ls -l /home/common|grep MonitorV3
echo "检查监控服务是否开启";/bin/netstat -antp|grep 41900 
echo "-----------------------------------------------------------"
echo "检查各服务器时间是否同步";/bin/date;/usr/sbin/rshrun -la date
echo "-----------------------------------------------------------"
echo "检查ntp服务是否正常";/bin/netstat -anup|grep ntpd
echo "-----------------------------------------------------------"
echo "backup的rsync进程是否开启";/usr/bin/rsh backup "ps afx|grep rsync"
exit 0
