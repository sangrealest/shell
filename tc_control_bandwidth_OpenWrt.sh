#!/bin/sh
#  定义进出设备(IDEV 内网接口，ODEV外网接口)
IDEV="br-lan"
ODEV="pppoe-wan"
#  定义总的上下带宽
UP="30mbit"
DOWN="30mbit"
#  定义每个受限制的IP上下带宽
#rate 起始带宽(默认限制，单IP限制带宽)
UPLOAD="1mbit"
DOWNLOAD="3mbit"
#ceil 最大带宽（当带宽有富余时单IP可借用的最大带宽，这个也是所有受限IP总带宽）
MUPLOAD="2mbit"
MDOWNLOAD="5mbit"
#内网IP段
INET="192.168.1."
# 受限IP范围，IPS 起始IP，IPE 结束IP。
IPS="100"
IPE="119"
# 清除网卡原有队列规则
tc qdisc del dev $ODEV root 2>/dev/null
tc qdisc del dev $IDEV root 2>/dev/null
# 定义最顶层(根)队列规则，并指定 default 类别编号
tc qdisc add dev $ODEV root handle 10: htb default 256
tc qdisc add dev $IDEV root handle 10: htb default 256
# 定义第一层的 10:1 类别 (上行/下行 总带宽)
tc class add dev $ODEV parent 10: classid 10:1 htb rate $UP ceil $UP
tc class add dev $IDEV parent 10: classid 10:1 htb rate $DOWN ceil $DOWN
#开始iptables 打标和设置具体规则
i=$IPS;
while [ $i -le $IPE ]
do
tc class add dev $ODEV parent 10:1 classid 10:2$i htb rate $UPLOAD ceil $MUPLOAD prio 1
tc qdisc add dev $ODEV parent 10:2$i handle 100$i: pfifo
tc filter add dev $ODEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i
tc class add dev $IDEV parent 10:1 classid 10:2$i htb rate $DOWNLOAD ceil $MDOWNLOAD prio 1
tc qdisc add dev $IDEV parent 10:2$i handle 100$i: pfifo
tc filter add dev $IDEV parent 10: protocol ip prio 100 handle 2$i fw classid 10:2$i
iptables -t mangle -A PREROUTING -s $INET$i -j MARK --set-mark 2$i
iptables -t mangle -A PREROUTING -s $INET$i -j RETURN
iptables -t mangle -A POSTROUTING -d $INET$i -j MARK --set-mark 2$i
iptables -t mangle -A POSTROUTING -d $INET$i -j RETURN
i=`expr $i + 1`
done

