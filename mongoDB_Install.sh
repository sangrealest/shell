#!/bin/bash

SlaveIP='10.128.129.45'
SlaveName='Databse-Slave'
SlaveMongoPort='27017'

ArbiterIP='10.128.129.46'
ArbiterName='Database-Arbiter'
ArbiterMongoPort='27017'

MasterIP='10.128.129.44'
MasterName='Database-Master'
MasterMongoPort='27017'

#Mongos config
MongosPort='27015'

#Mongo COnfig Server Config
MongoConfigIP='127.0.0.1'
MongoConfigName='Database-Config'
MongoConfigDBPath='/var/lib/mongodc'
MongoConfiglogpath='/var/log/mongodc'
MongoConfigPort='27014'


function createConfig(){
#    read -p "please inpute role name(master/slave/arbiter)" role
    role=$1
    mongoConfig="./mongod-$role"
    if [ ! -f "$mongoConfig" ]
    then
        echo "dbpath=/var/lib/mongodb-$role" >>$mongoConfig
        echo "logpath=/var/log/mongodb-$role/mongodb.log" >>$mongoConfig
        echo "logappend=true" >>$mongoConfig
        if [ "$role" == "master" ]
        then
            echo "port = $MasterMongoPort" >>$mongoConfig
        elif [ "$role" == "slave" ]
        then
            echo "port = $SlaveMongoPort" >>$mongoConfig
        elif [ "$role" == "arbiter" ]
        then
            echo "port = $ArbiterMongoPort" >>$mongoConfig
        fi
        echo "nohttpinterface=true" >>$mongoConfig
        echo "replSet = rs0" >>$mongoConfig
        chmod 644 /etc/$mongoConfig

    fi

}

function installMongoService(){
    
    echo "installing mongoserver"
    if [ ! -f "/usr/bin/mongo" ]
    then
        tar zxvf ./mongodb-linux-x86_64-2.4.9.tgz
        cd ./mongodb-linux-x86_64-2.4.9/bin/
        cp * /usr/bin
        cd ../.
    else
        echo "mongo server file already exist"
    fi

    cp mongod-$1.sh /etc/init.d/
    chmod 755 /etc/init.d/mongod-$1.sh
    /etc/init.d/mongod-$1.sh start
    i=1
    until ((i=="0"))
    do
        /bin/cat /var/log/mongodb-$1/mongodb.log | grep "waiting for connection"
        i=$?
        sleep 3
        echo "waiting for mongodb ready"
    done
    echo "mongodb is ready"
    sleep 4
}

function setupReplSet(){

    echo "setup mongodb replicationset"
    case $1 in
        master|Master|MASTER)
            member=("$SlaveName:$SlaveMongoPort")
            echo "rs.initiate()" | /usr/bin/mongo $MasterName:$MasterMongoPort
            sleep 3
            for count in ${member[@]}
            do
                echo "rs.add(\"$count\")" | /usr/bin/mongo $MasterName:$MasterMongoPort
                sleep 3
            done
            echo "rs.addArb(\"$ArbiterName:$ArbiterMongoPort\")"|/usr/bin/mongo $MasterName:$MasterMongoPort
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
        createConfig "master"
        installMongoService "master"
        setupReplSet "master"
    ;;

    slave|Slave|SLAVE)
        createConfig "slave"
        installMongoService "slave"
        setupReplSet "slave"
    ;;

    arbiter|Arbiter|ARBITER)
        createConfig "arbiter"
        installMongoService "arbiter"
        setupReplSet "arbiter"
    ;;

    mongos|Mongos|MONGOS)
        InstallMongoServerConfig
            getMongoServerConfig
    ;;


    all|All|ALL)
        #Install Slave
        createConfig "slave"
        installMongoService "slave"
        setupReplSet "slave"
        #install Arbiter
        createConfig "arbiter"
        installMongoService "arbiter"
        setupReplSet "arbiter"
        #Install Master
        createConfig "master"
        installMongoService "master"
        setupReplSet "master"

    ;;

    uninstall|Uninstall|UNINSTALL)
        #echo "this will remove all mongo files!!!"

        if [ -f "/usr/bin/pkill" ]
        then
             pkill -9 mongod
        else
            kill -9 `ps aux | grep mongo | grep -v grep | awk -F" " '{print $2}'`
            rm -rf /etc/mongo*
            rm -rf /etc/init.d/mongo*
            rm -rf /var/lib/mongo*
            rm -rf /var/log/mongo*
            rm -rf /usr/bin/mongo*
            rm -rf /var/run/mongo*
        fi
    ;;

    *)
        echo "Please inpute $0 Master, slave or ARBITER"
        exit 0
    ;;

    esac
