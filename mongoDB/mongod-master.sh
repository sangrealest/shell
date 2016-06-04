#!/bin/bash

#source /etc/mongod-start.conf
DBLocation='/var/lib/mongodb-master/'
LogFolder='/var/log/mongodb-master/'
StartProcess='/usr/bin/mongod -f /etc/mongod-master'
PidFile='/var/lib/mongodb-master/mongod-master.lock'

uid=`id | cut -d\( -f1 | cut -d= -f2`

if [ ! -d "$DBLocation" ];then
		mkdir $DBLocation
fi 

if [ ! -d "$LogFolder" ];then
		mkdir $LogFolder
fi 

if [ ! -f "$PidFile" ];then
		touch $PidFile
fi 

PidFileNum=`/bin/cat $PidFile`
CurrentPid=`ps aux|grep "$StartProcess"|grep -v "grep"|awk -F" " '{print $2}'`


ProcessStart()
{
        if [ "x$CurrentPid" != "x" ];then
                echo "mongod process already runing!! PID is $CurrentPid. "
        else
                exec $StartProcess &  
		sleep 2
                NewPidNum=`ps aux|grep "$StartProcess"|grep -v "grep"|awk -F" " '{print $2}'`
                echo "mongod process is running, pid is $NewPidNum"
                #PidFileNum=`/bin/cat $PidFile`
                #
                #if [ $NewPidNum != $PidFileNum ];then
                #       echo "Process is runing, but pid number is not match the pid file."
                #       echo "pid number is $NewPidNum"
                #fi
        fi
}


ProcessStop()
{
        if [ "x$CurrentPid" == "x" ];then
                echo "mongod process already Stop!! "
        else
                kill -15 $CurrentPid
                sleep 3
                NewPidNum=`ps aux|grep "\"$StartProcess\""|grep -v "grep"|awk -F" " '{print $2}'`
                if [ "x$NewPidNum" == "x" ];then
                        echo "mongod process is stop."
                else
                        kill -9 $NewPidNum
                        if [ "x$NewPidNum" != "x" ];then
                                echo "Can't kill mongod process, please call system administrator."
                        else
                                echo "mongod is stop."
                        fi
                fi
        fi
}

ProcessStatus()
{
        if [ "x$CurrentPid" != "x" ];then
                echo "mongod process is runing!! PID is $CurrentPid. "
        else
                echo "mongod not running."
        fi
}

case "$1" in
  start)
        ProcessStart
        ;;
  stop)
        ProcessStop
        ;;
  restart)
        ProcessStop
        CurrentPid=''
        ProcessStart
        ;;
  status)
        ProcessStatus
        ;;
  *)
        echo $"Usage: mongod {start|stop|status|restart}"
        RETVAL=2
        ;;
esac

