#!/bin/bash

function list(){
echo
echo
currentdate=$(date "+%Y-%m-%d %T")
cat<<EOF
               DATE:$currentdate
               ===============================
               1)add
               2)del
               3)update
               ===============================
EOF
}
function main(){
while :
do
     list
     echo -n " Please choose [1-7]:"
     read choose
     case $choose in
          7)
          exit;;
          *)
          clear
          continue;;
     esac
done
}
main

