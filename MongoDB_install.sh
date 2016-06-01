#!/bin/bash
#Author:Shanker
#set -x
#set -o nounset

source ./mongo_config

openssl rand -base64 741 >/etc/mongo.key
chmod 600 /etc/mongo.key

function createConfig(){
    role=$1
    mongoConfig="./mongod-$role"
    if [ ! -f "$mongoConfig" ]
    then
        echo "dbpath=/var/lib/mongodb-$role" >>$mongoConfig
        echo "logpath=/var/log/mongodb-$role/mongodb.log" >>$mongoConfig
        echo "logappend=true" >>$mongoConfig
        echo "keyFile=$MongoKeyFile" >>$mongoConfig
        if [ "$role" == "master" ]
        then
            echo "port=$MasterMongoPort" >>$mongoConfig
        elif [ "$role" == "slave" ]
        then
            echo "port=$SlaveMongoPort" >>$mongoConfig
        elif [ "$role" == "arbiter" ]
        then
            echo "port=$ArbiterMongoPort" >>$mongoConfig
        fi
        echo "nohttpinterface=true" >>$mongoConfig
        echo "nojournal=true" >>$mongoConfig
        echo "replSet=rs0" >>$mongoConfig

        cp $mongoConfig /etc/
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
        cd ../..
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
    member="$SlaveName:$SlaveMongoPort"
    echo "rs.initiate()" | /usr/bin/mongo $MasterName:$MasterMongoPort
    sleep 3
    echo "rs.add(\"$count\")" | /usr/bin/mongo $MasterName:$MasterMongoPort
    sleep 3
    echo "rs.addArb(\"$ArbiterName:$ArbiterMongoPort\")"|/usr/bin/mongo $MasterName:$MasterMongoPort
    echo "rs.status()"|/usr/bin/mongo $MasterName:$MasterMongoPort
}

case $1 in
    "master"|"Master")
        createConfig "master"
        installMongoService "master"
        setupReplSet 
        ;;

    "slave"|"Slave")
        createConfig "slave"
        installMongoService "slave"
        ;;

    "arbiter"|"Arbiter")
        createConfig "arbiter"
        installMongoService "arbiter"
        ;;
    "uninstall"|"Uninstall")
        echo "this will remove all mongo files!!!"

        if [ -f "/usr/bin/pkill" ]
        then
             pkill -9 mongod
        else
            kill -9 `ps aux | grep mongo | grep -v grep | awk -F" " '{print $2}'`
        fi
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
