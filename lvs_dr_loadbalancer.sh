#!/bin/bash
#
# LVS script for VS/DR
# chkconfig: - 90 10
#
. /etc/rc.d/init.d/functions
#
VIP=192.168.80.88
DIP=192.168.80.130
RIP1=192.168.80.131
RIP2=192.168.80.132
PORT=80
RSWEIGHT1=2
RSWEIGHT2=5

#
case "$1" in
start)           

  /sbin/ifconfig eth1:0 $VIP broadcast $VIP netmask 255.255.255.255 up
  /sbin/route add -host $VIP dev eth1:0

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
  /sbin/ifconfig eth1:0 down
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
