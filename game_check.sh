#!/bin/bash
##init.tar.gz and CGI.pm-3.63.tar.gz java.tar.gz MonitorV3.tar.gz  jakarta-tomcat-5.5.9.tar.gz  
##libs.tar.gz  maintenance.tar.gz  MegaCli64  MegaCli rsync.sh     sudoers
#Log_authorized_keys  Web_authorized_keys snmptrapd.conf  snmpd.conf  snmp.conf 
##1.system init
##2.610/620/server init and check
##3.ntp problem
##4.sync xml, check xml and time configuration
##5.after published, check processes and ports



ip_chcek ()
	{
	IN_IP=`/sbin/ip a | grep -E "eth2|eth0" | grep 254 | awk '{print $2}'| cut -d "/" -f 1`
	OUT_IP=`/sbin/ip a | grep eth1 | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	echo "------------------------manager_IP:------------------------"
	echo "IN_IP:" $IN_IP
	echo "OUT_IP:" $OUT_IP
	BIN_IP=`rsh backup /sbin/ip a | grep -E "eth2|eth0"  | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	BOUT_IP=`rsh backup /sbin/ip a | grep eth1 | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	echo "------------------------backup_IP:-------------------------"
	echo "IN_IP:" $BIN_IP
	echo "OUT_IP:" $BOUT_IP
	DIN_IP=`rsh database /sbin/ip a | grep -E "eth2|eth0"  | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	echo "------------------------database_IP:--------------------------"
	echo "IN_IP:" $DIN_IP
	GIN_IP=`rsh game1 /sbin/ip a | grep -E "eth2|eth0"  | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	GOUT_IP=`rsh game1 /sbin/ip a | grep eth1 | grep inet | awk '{print $2}'| cut -d "/" -f 1`
	echo "------------------------game1_IP:-------------------------"
	echo "IN_IP:" $GIN_IP
	echo "OUT_IP:" $GOUT_IP
}
raid_check ()
	{
	echo "Check manager disk info";/root/MegaCli -PDlist -aALL |grep Error
	echo "-----------------------------------------------------------"
    	echo "Check game1 disk info";/usr/bin/rsh game1 /root/MegaCli -PDlist -aALL |grep Error
	echo "-----------------------------------------------------------"
	echo "Check database disk info";/usr/bin/rsh database /root/MegaCli -PDlist -aALL |grep Error
	echo "-----------------------------------------------------------"
	echo "Check backup disk info";/usr/bin/rsh backup /root/MegaCli -PDlist -aALL |grep Error
	echo "-----------------------------------------------------------"
	echo "Manager FW Version:";/root/MegaCli -AdpAllInfo -aALL|grep FW
	echo "-----------------------------------------------------------"
	echo "Database FW Version:";/usr/bin/rsh database /root/MegaCli -AdpAllInfo -aALL|grep FW
	echo "-----------------------------------------------------------"
	echo "Backup FW Version:";/usr/bin/rsh backup /root/MegaCli -AdpAllInfo -aALL|grep FW
}
	
	
disk_check ()
	{
	echo "-------------------------disk_mount------------------------"
    	echo "manager disk:"; df -h
	echo "-----------------------------------------------------------"
    	echo "game1 disk:"; rsh  game1 df -h |grep -A2  mana
	echo "-----------------------------------------------------------"
   	echo "database disk:";  rsh database df -h |grep -A2  mana
	echo "-----------------------------------------------------------"
   	echo "backup disk:";  rsh backup df -h |grep -A2  mana
	echo "-----------------------------------------------------------"
}
	
memory_check ()
        {
        a=`cat /proc/meminfo  | grep MemTotal| awk '{print $2}'`
        b=`cat /proc/meminfo  | grep MemFree| awk '{print $2}'`
        c=`expr $a - $b`
        d=`expr  $c \* 100`
        e=`expr $d / $a`
        f=`free -g | grep ^Mem | awk '{print $2}'`
        echo "------------------------memory_check------------------------"
        echo "manager           total: $f(G) Use: $e%" 
        for i in database backup game1
        do
                a=`rsh $i cat /proc/meminfo  | grep MemTotal| awk '{print $2}'`
                b=`rsh $i cat /proc/meminfo  | grep MemFree| awk '{print $2}'`
                c=`expr $a - $b`
                d=`expr  $c \* 100`
                e=`expr $d / $a`
                f=`rsh $i free -g | grep ^Mem | awk '{print $2}'`

                echo "$i                total $f(G) Use: $e%"
        done
}

	
kernel_check ()
	{
	echo "------------------------kernel_check------------------------"
	/bin/uname -a;/usr/sbin/rshrun -la "/bin/uname -a"
}

hosts_check ()
	{
	echo "----------------------hosts_check---------------------------"
	echo "manager: /etc/hosts file update ";/bin/cat /etc/hosts
	echo "------------------------------------------------------------"
	echo "game1: /export/game1/etc/hosts file update ";/bin/cat /export/game1/etc/hosts
	echo "------------------------------------------------------------"
	echo "database: /export/database/etc/hosts file update ";/bin/cat /export/database/etc/hosts
	echo "------------------------------------------------------------"
	echo "backup: /export/backup/etc/hosts file update ";/bin/cat /export/backup/etc/hosts
	echo "-----------------------------------------------------------"
	echo "Check /etc/resolv.conf文件";
	/bin/cat > /etc/resolv.conf << EOF
nameserver 61.55.177.171
nameserver 101.68.213.82
EOF
/bin/cat /etc/resolv.conf
	echo "-----------------------------------------------------------"	
}
keys_check ()
	{
	echo "---------------authorized_keys_check-----------------------"
	md5sum /home/web/.ssh/authorized_keys
	a="8b4091d13172a2f619b419782f0cfbb4"
	b="`md5sum /home/web/.ssh/authorized_keys|awk '{print $1}'`"
	if [ "$a" == "$b" ]
	then
	echo "/home/web/.ssh/authorized_keys  already the latest "
	else
	echo "authorized_keys  error "
	fi
	echo "-----------------------------------------------------------"
	md5sum /home/log/.ssh/authorized_keys
	c="6547b4802a828efb52cdad11a080014f"
	d="`md5sum /home/log/.ssh/authorized_keys|awk '{print $1}'`"
	if [ "$c" == "$d" ]
	then
	echo "/home/log/.ssh/authorized_keys  already the latest "
	else
	echo "authorized_keys  error "
	fi
	echo "-----------------------------------------------------------"
}
	
db_uname_check ()
	{
	echo "Check database:/dbf/ database files";/usr/bin/rsh database "/bin/ls -l /dbf/"
	echo "-----------------------------------------------------------"
	echo "Check backup:/export/ uniqued db files";/usr/bin/rsh backup "/bin/ls -l /export/"
	echo "-----------------------------------------------------------"
}
dirstat_check ()
	{
	echo "/export/web/ authority :";/bin/ls -l /export/|grep web
	echo "/home/web/ authority :";/bin/ls -l /home/|grep web
}

log_check()
	{
	echo "-----------------check log----------------------------------"
	du -sh /export/logs
    	du -sh /export/cashstat
	du -sh /var/log/brief.tar.gz
}	
user_check ()
	{
	echo "----------------------------user-check---------------------"
	/usr/bin/id rewu_log > /dev/null
	if [ $? -ne 0 ] ;then
		echo "user rewu_log not exist,you should be create it "
	else
		echo "user rewu_log exist"
	fi
	echo "-----------------------------------------------------------"
}
	
services_check ()
	{
	echo "Check MonitorV3 installed";/bin/ls -l /home/common|grep MonitorV3
	echo "Check monitor service";/bin/netstat -antp|grep 41900 
	echo "-----------------------------------------------------------"
	echo "Check sub machines time";/bin/date;/usr/sbin/rshrun -la date
	echo "-----------------------------------------------------------"
	echo "Check ntp service";/bin/netstat -anup|grep ntpd
	echo "-----------------------------------------------------------"
	echo "backup的rsync process";/usr/bin/rsh backup "ps afx|grep rsync"
}
ntp_check()
	{
	echo "Syncing time, pls wait....."
	/usr/sbin/rshrun --loadall /usr/sbin/ntpdate -b -p 8 manager >/dev/null 2>/dev/null
	/bin/date;/usr/sbin/rshrun -la "/bin/date"
}
tar_620()
	{
	dir=`pwd`
    	if [ -f $dir/init.tar.gz ];then
       		echo "init.tar.gz unzipping..."
		if [ -d /export/tmp/620 ]
		then
        		cd /export/tmp/620 && rm -rf ./*
		else
           		mkdir -p /export/tmp/620
        	fi
        	cp $dir/init.tar.gz /export/tmp/620
        	cd /export/tmp/620
        	tar zxvf init.tar.gz
    	else
        	echo "no init.tar.gz, please go to that directory"
		exit 1
	fi  
}
tar_610()
	{
	dir=`pwd`
	if [ -f $dir/init.tar.gz ];then
		echo "init.tar.gz unzipping ..."
        	if [ -d /export/tmp/610 ]
        	then
        		cd /export/tmp/610 && rm -rf ./*
       		else
            		mkdir -p /export/tmp/610
        	fi
       		cp $dir/init.tar.gz /export/tmp/610
		cd /export/tmp/610
		tar zxvf init.tar.gz
	else
		echo " no init.tar.gz, pls go to the init direcotry "
		exit 1
	fi
}	
tar_virt()
	{
	dir=`pwd`
	if [ -f $dir/init.tar.gz ];then
		echo "init.tar.gz unzipping ..."
        	if [ -d /export/tmp/virt ]
        	then
        		cd /export/tmp/virt && rm -rf ./*
       		else
            		mkdir -p /export/tmp/virt
        	fi
       		cp $dir/init.tar.gz /export/tmp/virt
		cd /export/tmp/virt
		tar zxvf init.tar.gz
	else
		echo " no init.tar.gz, pls go to the init direcotry "
		exit 1
	fi
}	
mk_dir()
	{
	echo "creating directory"
	if [ ! -d /etc/ssl/private/client ]
	then
		mkdir -p /etc/ssl/private/client
	fi
	mkdir /export/web
	mkdir /usr/java
        mkdir -p /home/common
        mkdir -p /home/web/.ssh
        mkdir -p /home/log/.ssh
        chown web.web -R /export/web
        chmod 755 /export/web
        chown common.common -R /home/common
        chmod 755 /home/common
        chown web.web /home/web
        chmod 700 /home/web
        chown log.log -R /home/log
        chmod 700 /home/log
	echo "finished"
}
add_user ()
	{
	echo "Creating rewu_log user"
	/usr/bin/id rewu_log &>/dev/null
	if [ $? -ne 0 ];then
	useradd rewu_log
	fi
}

add_authorized ()
	{
	echo "add log and web ssh key"
	cp Web_authorized_keys /home/web/.ssh/authorized_keys
	chown web.web /home/web/.ssh/authorized_keys
	chmod 600 /home/web/.ssh/authorized_keys
	cp Log_authorized_keys /home/log/.ssh/authorized_keys   
	chown log.log /home/log/.ssh/authorized_keys
	chmod 600 /home/log/.ssh/authorized_keys
}
init_java_tomcat_MonitorV3 ()
	{
	tar zxvf java.tar.gz -C /usr/
	tar zxvf jakarta-tomcat-5.5.9.tar.gz -C /usr/local/
	tar zxf MonitorV3.tar.gz -C /home/common
	chown -R common.common /home/common/MonitorV3
	su - common -c "echo \"*/2 * * * * netstat -ntl | grep 41900 > /dev/null 2>&1 || /home/common/MonitorV3/Server /home/common/MonitorV3/Server.conf >/dev/null 2>&1\" | crontab"
}
copy_sudoers()
	{
	if [ -d /export/tmp/610 ];then
        dir="/export/tmp/610"
        elif [ -d /export/tmp/620 ];then
        dir="/export/tmp/620"
        else
        dir="/export/tmp/virt"
        fi
	cp $dir/sudoers /etc/
}
copy_lib ()
	{
	tar zxvf libs.tar.gz
	\cp -av libs/libgcc_s.so.1 /lib/
	\cp -av libs/libstdc++.so.5.0.7 /usr/lib
	ln -s /usr/lib/libstdc++.so.5.0.7 /usr/lib/libstdc++.so.5
	for name in game1 database backup
        do
        	rcp  libs/libpcre.so.0  $name:/lib/
        	rcp  libs/libgcc_s.so.1 $name:/lib/
        	rcp  libs/libstdc++.so.5.0.7 $name:/lib/
        	rcp  libs/libpcre.so.0 $name:/usr/lib/
        	rcp  libs/libgcc_s.so.1 $name:/usr/lib/
        	rcp  libs/libstdc++.so.5.0.7 $name:/usr/lib/
        	rcp  libs/libz.so.1 $name:/usr/lib/
        	rsh  $name "ln -s /usr/lib/libstdc++.so.5.0.7 /usr/lib/libstdc++.so.5"
	done
}
tarx_maintenace()
	{
	if [ -d /export/tmp/610 ];then
        dir="/export/tmp/610"
        elif [ -d /export/tmp/620 ];then
        dir="/export/tmp/620"
        else
        dir="/export/tmp/virt"
        fi
	cd $dir
	tar zxvf maintenance.tar.gz -C /root/
}
copy_MegaCli64 ()
	{
	if [ -d /export/tmp/610 ];then
        dir="/export/tmp/610"
        elif [ -d /export/tmp/620 ];then
        dir="/export/tmp/620"
        else
        dir="/export/tmp/virt"
        fi
	rcp $dir/MegaCli64 game1:/root/MegaCli
	rcp $dir/MegaCli64 database:/root/MegaCli
	rcp $dir/MegaCli64 backup:/root/MegaCli
	cp  $dir/MegaCli64 /root/MegaCli
	chmod +x /root/MegaCli
	rshrun -la "chmod +x /root/MegaCli"
}
copy_MegaCli ()
	{
	if [ -d /export/tmp/610 ];then
        dir="/export/tmp/610"
        elif [ -d /export/tmp/620 ];then
        dir="/export/tmp/620"
        else
        dir="/export/tmp/virt"
        fi
	rcp $dir/MegaCli game1:/root/MegaCli
	rcp $dir/MegaCli database:/root/MegaCli
	rcp $dir/MegaCli backup:/root/MegaCli
	cp  $dir/MegaCli /root/MegaCli
	chmod +x /root/MegaCli
	rshrun -la "chmod +x /root/MegaCli"
}	
	
install_CGI ()
	{
	tar zxvf CGI.pm-3.63.tar.gz
	cp -r CGI.pm-3.63 /root/ 
	rcp -r CGI.pm-3.63 database:/root/ 
	rcp -r CGI.pm-3.63 game1:/root/ 
	rcp -r CGI.pm-3.63 backup:/root/ 
	cd /root/CGI.pm-3.63
	/usr/bin/perl Makefile.PL  
	/usr/bin/make && /usr/bin/make install
	rsh database "cd /root/CGI.pm-3.63;/usr/bin/perl Makefile.PL;/usr/bin/make && /usr/bin/make install "
	rsh backup   "cd /root/CGI.pm-3.63;/usr/bin/perl Makefile.PL;/usr/bin/make && /usr/bin/make install "
}
	
start_services ()
	{
	##"snmp service"
	if [ -d /export/tmp/610 ];then
	dir="/export/tmp/610"
	elif [ -d /export/tmp/620 ];then
	dir="/export/tmp/620"
	else
	dir="/export/tmp/virt"
	fi                     
	cp $dir/snmp* /etc/snmp/
	rcp $dir/snmp* database:/etc/snmp/
	rcp $dir/snmp* backup:/etc/snmp/
	rcp $dir/snmp* game1:/etc/snmp/
	/etc/init.d/snmpd restart
	rshrun -la "/etc/init.d/snmpd restart"
	/sbin/chkconfig snmpd on
	rshrun -la "/sbin/chkconfig snmpd on"
	##" start ntp service "
	/etc/init.d/ntpd restart
	##echo "chkconfig rsyslog on"
	rshrun -la "/etc/init.d/rsyslog start || /etc/init.d/syslog start" 
	rshrun -la "/sbin/chkconfig rsyslog on"
	##" start backup_rsync service "
	#rsh backup 'pgrep rsync | xargs kill' &>/dev/null
	if [ -d /export/tmp/620 ]
	then
	rcp /export/tmp/620/rsync.sh backup:/root/
	elif [ -d /export/tmp/610 ]
	then
	rcp /export/tmp/610/rsync.sh backup:/root/
	else
	rcp /export/tmp/virt/rsync.sh backup:/root/
	fi
	rsh backup '/usr/bin/rsync --daemon' 
	rsh backup  'ps aux | grep rsync | grep -v grep' 
}

rhost ()
	{
	##backup add /root/.rhosts### 
	rsh backup  'echo -e "manager\ndatabase" > /root/.rhosts'
}	
	
	
clear_log()
        {
	mkdir -p /export/web/olddata/`date +%F`
    	cp -r /export/logs /export/web/olddata/`date +%F`
    	cp -r /export/cashstat /export/web/olddata/`date +%F`
    	mv /var/log/brief.tar.gz /export/web/olddata/`date +%F`
	chown -R web.web /export/web/olddata/`date +%F`
    	cd /export/logs/ && rm -rf ./*
    	cd /export/cashstat/ && rm -rf ./*
}	  

xml_check()
	{
	R='replace.*'
	xml="$(cat /home/super/update/*package/config/ip_xml.conf |grep "$(cat /etc/sysconfig/network-scripts/ifcfg-eth2 |grep IP|cut -d"=" -f2|cut -d"." -f1-3)" |awk '{print $2}')"
	echo "Check 的xml name:" $xml
	echo "-------------------Check zoneid------------------------------"
	/bin/grep ${R}zoneid= /home/super/update/*package/config/$xml;
	echo "-------------------Check aid---------------------------------"
	/bin/grep ${R}aid= /home/super/update/*package/config/$xml;
	echo "-------------------Check GameUniquename----------------------"
	/bin/grep ${R}linename /home/super/update/*package/config/$xml;
	echo "-------------------Check Uniquename--------------------------"
	/bin/grep ${R}uniquenameserverip /home/super/update/*package/config/$xml;
	echo "-------------------Check LinkIP------------------------------"
	/bin/grep ${R}linkip /home/super/update/*package/config/$xml;
	echo "-------------------Check Code--------------------------------"
	/bin/grep code= /home/super/update/*package/config/$xml | awk -F '"' '{print $6}';
	echo "-------------------Check AUserver----------------------------"
	/bin/grep ${R}authserver /home/super/update/*package/config/$xml;
}
		
game_process()
	{
	/usr/sbin/rshrun -la 'ps -ef | grep game'
    	for gp in $(rshrun -la ps -ef |grep game |awk '{print $8}' |sort |uniq |grep -v -E "bash|^$")
   	do
    		echo  "$(echo $gp|awk  -F"/" '{print $3}' ) = $(rshrun -la ps -ef |grep $gp |wc -l)"
   	done
}

port_check()
	{
	echo " deteck delivery port   29200（au）｜29400(db)｜29401(uniquename)｜29712(plug-in)| 49500(cross-servers)"
    	rsh delivery /bin/netstat -anpt | grep -E "29200|29400|29401|29712|49500"
   	echo "-----------------------------------------------------------"
   	echo " deteck 29000 [0-2] port status(link)"
    	rsh link1  /bin/netstat -ntlp | grep  2900
    	rsh link2  /bin/netstat -ntlp | grep  2900
}

list(){
    echo
    echo "1) initialize your machine"
    echo "2) check 610 machine"
    echo "3) check 620 machine"
    echo "4) check virtual machine"
    echo "5) check log xml and delete brief"
    echo "6) check process and ports"
    echo "7) ntpdate your local machine time"
    echo "et) exit"
    
}

while true
do
    list
    echo "please inpute your choise"
    read choise
    
    case "$choise" in
    
    	p|1)
    		ip_chcek
    		disk_check
    		raid_check
    		kernel_check
    		memory_check 
    		user_check
    		log_check
    		dirstat_check
    		keys_check
    		hosts_check 
    		db_uname_check
    		services_check		
    	;;
    	610|2)
    		tar_610
    		mk_dir
    		add_user
    		add_authorized
    		init_java_tomcat_MonitorV3
    		copy_sudoers
    		copy_MegaCli
    		tarx_maintenace
    		rhost
    		start_services	
    	;;
    	620|3)
    		tar_620
    		mk_dir
    		add_user
    		add_authorized
    		init_java_tomcat_MonitorV3
    		copy_lib
    		copy_MegaCli64
    		copy_sudoers
    		install_CGI
    		tarx_maintenace
    		rhost
    		start_services	
    	;;
    	virt|4)
    		tar_virt
    		mk_dir
    		add_user
    		add_authorized
    		init_java_tomcat_MonitorV3
    		copy_sudoers
    		copy_MegaCli
    		tarx_maintenace
    		rhost
    		start_services	
    	;;
    	x|5)
    		clear_log
    		xml_check
    	;;
    	g|6)
    		game_process
    		port_check
    	;;
    	n|7)	
    		ntp_check
    	;;
    	et)
    		exit 1
    	;;
    esac
    
done

