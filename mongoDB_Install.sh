#!/bin/bash

#source ./configuration.conf
#Mongo Server Info
SlaveIP='10.128.129.45'
SlaveName='Database-Slave'
SlaveMongoPort='27017'

ArbiterIP='10.128.129.46'
ArbiterName='Database-Arbiter'
ArbiterMongoPort='27017'

MasterIP='10.128.129.44'
MasterName='Database-Master'
MasterMongoPort='27017'


#Mongo s config
MongosPort='27015'


#Mongo Config Server Conffig
MongoConfigIP='127.0.0.1'
MongoConfigName='Database-Config'
MongoConfigDBPath='/var/lib/mongodc'
MongoConfiglogpath='/var/log/mongodc'
MongoConfigPort='27014'
MongoConfigkeyFile = '/etc/mongodb.key'




function CreateConfig(){
    echo " Create Mongo config file................."
    rolename=$1
    mongoConfig="./monggod-$rolename"
    if [ ! -f "$mongoConfig" ]

    echo "dbpath=/var/lib/mongodb-$rolename" >> $mongoConfig
    echo "logpath=/var/log/mongodb-$character/mongodb.log" >> $mongoConfig
    echo "logappend=true" >> $mongoConfig
    if [ "$rolename" == "master" ]
    then
        echo "port = $MasterMongoPort" >> $mongoConfig
    elif [ "$rolename" == "slave" ]
    then
        echo "port = $SlaveMongoPort" >> $mongoConfig
    elif [ "$rolename" == "arbiter" ]
    then
        echo "port = $ArbiterMongoPort" >> $mongoConfig
    fi
    echo "nohttpinterface=true" >>$mongoConfig
    echo "replSet = rs0" >>$mongoConfig
    cp $mongoConfig /etc/
    chmod 644 /etc/$mongoConfig

}

function InstallMongoService(){

    echo "Installing MongoServer config file..........."
    if [ ! -f "/usr/bin/mongo" ]
    then
    	tar zxvf ./mongodb-linux-x86_64-2.4.9.tgz
    	cd ./mongodb-linux-x86_64-2.4.9/bin/
    	cp * /usr/bin
    	cd ../..
    else
    	echo "Mongo server file already exsit"
    fi
    cp mongod-$1.sh /etc/init.d/
    chmod 755 /etc/init.d/mongod-$1.sh
    /etc/init.d/mongod-$1.sh start 

    i=1
    until ((i=="0"))
    do 
    	/bin/cat /var/log/mongodb-$1/mongodb.log | grep "waiting for connection on port"
    	i=$?
    	sleep 3
    	echo "Waiting for mongodb ready"
    done
    echo "Mongodb is ready"
    sleep 4

}

function SetupReplicationSet(){

    echo "Setup MongoDB ReplicationSet ......."
    case $1 in
        master|Master|MASTER)
			member=("$SlaveName:$SlaveMongoPort")
			echo "rs.initiate()" | /usr/bin/mongo $MasterName:$MasterMongoPort
			sleep 3
			for count in ${member[@]}
			do
				echo "rs.add(\"$count\")"|/usr/bin/mongo $MasterName:$MasterMongoPort
				sleep 3
			done
			echo "rs.addArb(\"$ArbiterName:$ArbiterMongoPort\")"|/usr/bin/mongo $MasterName:$MasterMongoPort    
			sleep 3
			echo "rs.status()"|/usr/bin/mongo $MasterName:$MasterMongoPort
    ;;
    slave|Slave|SLAVE)
	exit 0
	;;
	arbiter|Arbiter|ARBITER)
	exit 0
	;;
	*)
	exit 0
	;;		
    esac

}

case $1 in
    master|Master|MASTER)
        CreateConfig "master"
        StartMongoInstall "master"
        SetupReplicationSet "master"
    ;;

    slave|Slave|SLAVE)
        CreateConfig "slave"
        StartMongoInstall "slave"
        SetupReplicationSet "slave"
    ;;

    arbiter|Arbiter|ARBITER)
        CreateConfig "arbiter"
        StartMongoInstall "arbiter"
        SetupReplicationSet "arbiter"
    ;;

    mongos|Mongos|MONGOS)
        InstallMongoServerConfig
            getMongoServerConfig
    ;;


    all|All|ALL)
        #Install Slave
        CreateConfig "slave"
        StartMongoInstall "slave"
        SetupReplicationSet "slave"
        #install Arbiter
        CreateConfig "arbiter"
        StartMongoInstall "arbiter"
        SetupReplicationSet "arbiter"
        #Install Master
        CreateConfig "master"
        StartMongoInstall "master"
        SetupReplicationSet "master"

    ;;

    uninstall|Uninstall|UNINSTALL)
        #echo "this will remove all mongo files!!!"

        pkill -9 mongo
        rm -rf /etc/mongo*
        rm -rf /etc/init.d/mongo*
        rm -rf /var/lib/mongo*
        rm -rf /var/log/mongo*
        rm -rf /usr/bin/mongo*
        rm -rf /var/run/mongo*
    ;;

    *)
        echo "Please inpute $0 Master, slave or ARBITER"
        exit 0
    ;;

    esac
