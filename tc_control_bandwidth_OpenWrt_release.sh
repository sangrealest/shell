#!/bin/sh
# 基于 此处脚本修改xiaoh www.linuxbyte.org
#内网IP段
INET="192.168.1."
# 受限IP范围，IPS 起始IP，IPE 结束IP。
IPS="100"
IPE="119"
# 清除网卡原有队列规则
tc qdisc del dev $ODEV root 2>/dev/null
tc qdisc del dev $IDEV root 2>/dev/null
#开始清理iptables 打标和设置具体规则
p=$IPS;
while [ $p -le $IPE ]
do
iptables -t mangle -D PREROUTING -s $INET$p -j MARK --set-mark 2$p
iptables -t mangle -D PREROUTING -s $INET$p -j RETURN
iptables -t mangle -D POSTROUTING -d $INET$p -j MARK --set-mark 2$p
iptables -t mangle -D POSTROUTING -d $INET$p -j RETURN
p=`expr $p + 1`
done
