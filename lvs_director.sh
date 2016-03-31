#!/bin/bash
#
# LVS script for VS/DR
# chkconfig: - 90 10
#
. /etc/rc.d/init.d/functions
#
VIP=172.16.100.1
DIP=172.16.100.2
RIP1=172.16.100.7
RIP2=172.16.100.8
PORT=80
RSWEIGHT1=2
RSWEIGHT2=5

#
case "$1" in
start)           

  /sbin/ifconfig eth0:1 $VIP broadcast $VIP netmask 255.255.255.255 up
  /sbin/route add -host $VIP dev eth0:0

# Since this is the Director we must be able to forward packets
  echo 1 > /proc/sys/net/ipv4/ip_forward

# Clear all iptables rules.
  /sbin/iptables -F

# Reset iptables counters.
  /sbin/iptables -Z

# Clear all ipvsadm rules/services.
  /sbin/ipvsadm -C

# Add an IP virtual service for VIP 192.168.0.219 port 80
# In this recipe, we will use the round-robin scheduling method. 
# In production, however, you should use a weighted, dynamic scheduling method. 
  /sbin/ipvsadm -A -t $VIP:80 -s wlc

# Now direct packets for this VIP to
# the real server IP (RIP) inside the cluster
  /sbin/ipvsadm -a -t $VIP:80 -r $RIP1 -g -w $RSWEIGHT1
  /sbin/ipvsadm -a -t $VIP:80 -r $RIP2 -g -w $RSWEIGHT2

  /bin/touch /var/lock/subsys/ipvsadm &> /dev/null
;; 

stop)
# Stop forwarding packets
  echo 0 > /proc/sys/net/ipv4/ip_forward

# Reset ipvsadm
  /sbin/ipvsadm -C

# Bring down the VIP interface
  /sbin/ifconfig eth0:0 down
  /sbin/route del $VIP
  
  /bin/rm -f /var/lock/subsys/ipvsadm
  
  echo "ipvs is stopped..."
;;

status)
  if [ ! -e /var/lock/subsys/ipvsadm ]; then
    echo "ipvsadm is stopped ..."
  else
    echo "ipvs is running ..."
    ipvsadm -L -n
  fi
;;
*)
  echo "Usage: $0 {start|stop|status}"
;;
esac


RealServer脚本:

#!/bin/bash
#
# Script to start LVS DR real server.
# chkconfig: - 90 10
# description: LVS DR real server
#
.  /etc/rc.d/init.d/functions

VIP=172.16.100.1

host=`/bin/hostname`

case "$1" in
start)
       # Start LVS-DR real server on this machine.
        /sbin/ifconfig lo down
        /sbin/ifconfig lo up
        echo 1 > /proc/sys/net/ipv4/conf/lo/arp_ignore
        echo 2 > /proc/sys/net/ipv4/conf/lo/arp_announce
        echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
        echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce

        /sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up
        /sbin/route add -host $VIP dev lo:0

;;
stop)

        # Stop LVS-DR real server loopback device(s).
        /sbin/ifconfig lo:0 down
        echo 0 > /proc/sys/net/ipv4/conf/lo/arp_ignore
        echo 0 > /proc/sys/net/ipv4/conf/lo/arp_announce
        echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
        echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce

;;
status)

        # Status of LVS-DR real server.
        islothere=`/sbin/ifconfig lo:0 | grep $VIP`
        isrothere=`netstat -rn | grep "lo:0" | grep $VIP`
        if [ ! "$islothere" -o ! "isrothere" ];then
            # Either the route or the lo:0 device
            # not found.
            echo "LVS-DR real server Stopped."
        else
            echo "LVS-DR real server Running."
        fi
;;
*)
            # Invalid entry.
            echo "$0: Usage: $0 {start|status|stop}"
            exit 1
;;
esac
