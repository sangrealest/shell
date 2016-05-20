#!/bin/bash
#Author: Shanker
#sync packages from publish servers to produtions, automately enable iptables and sync package.

function usage(){

echo "============================================================================="
echo "-i    the method of iptables, ie: I for add one rule or D for Delete one rule"
echo "-s    the source ip address"
echo "-f    the filename of source file"
echo "-d    the dest path"
echo "$0 -s 183.136.229.71 -f newrelease.tgz -d /export/tmp/shanker/mergedb/ -i I"
echo "add one iptables rule, $0 -s 183.136.229.71 -i I"
echo "delete the iptables rule, $0 -s 183.136.229.71 -i D"
echo "Don't forget to delete the iptables rules you opened"
echo "=============================================================================="
}

while getopts ":i:s:f:d:h" opts
do
    case $opts in
        s)
            source="$OPTARG"
            ;;
        f)
            filename="$OPTARG"
            ;;
        i)
            case $OPTARG in
                i|I|a)
                    iptables -I INPUT -s $source -j ACCEPT
                    ;;
                D|d)
                    iptables -D INPUT -s $source -j ACCEPT
                    ;;
                *)
                    echo "unknown method of iptables, please use -I or -D"
                    ;;
            esac
            ;;
        d)
            dstdir=$OPTARG
            /usr/bin/rsync -avvzP $source::backup/$filename $dstdir
            ;;
    h)
        usage
        ;;
    *)
        echo "Unknow pameter, please use $0 -h for help"
        ;;
    esac
done

