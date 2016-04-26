#!/bin/bash

##################################################################################
# Read stock number data from ./stock_num_file.txt 
#
#
#
###################################################################################
STOCK_NUM_FILE="./stock_num.dat"
ITEM_COLOR="\033[34m"
COLOR_RESET="\033[0m"
COLOR_RED="\033[31m"
COLOR_GREEN="\033[32m"

function ERRTRAP()
{
	echo "[LINE:$1] Error: Comand or Function exited with status $?"

}

function print_array()
{
	i=0	
	for elem in "$@"
	do
		echo $((i++)) $elem
	done
}

function read_data_file()
{
	i=0
	if [ ! -e "./stock_num.dat" ]
	then
		echo "ERROR: The stock_num.dat isn't existed!"
		exit 0
	fi

	while read line
	do
		STOCK_NUM[$i]=$line
		let i+=1
	done < $STOCK_NUM_FILE
	for ((i=0; i < ${#STOCK_NUM[@]}; i++ ))
	do
	#echo "${STOCK_NUM[$i]}"
		get_info ${STOCK_NUM[$i]}		
	done
}

############################################################################
#
# funciton:  get_info(arg1)
#
# result: Get stock information from Internet
#
############################################################################
function get_info()
{
	stock_info=`curl http://hq.sinajs.cn/list=$1 2>/dev/null | sed -n -e 's/var.*=\"//' -e 's/ //g' -e 's/\";$//p'`
#	echo "$stock_info"
#	s_name=`echo "$stock_info" | sed -n 's/,.*$//p'`
#	echo $s_name
#	stock_data=`echo "$stock_info" | sed -n 's/'$s_name',//p'`
#	echo $stock_data
	s_num=$1
	if [ "$stock_info" != "" ];then
		prase_info $stock_info
		display_info
	else
		echo "Exception:Can't find any infomation about $s_num"
	fi
}

function prase_info()
{
	eval $(echo $1 | awk '{split($0,array,","); for(i in array) print "stock_info_array["i"]="array[i]}')
	s_name=${stock_info_array[1]}	
	s_today_open=${stock_info_array[2]}
	s_lastday_close=${stock_info_array[3]}
	s_current_price=${stock_info_array[4]}
	s_today_highest=${stock_info_array[5]}
	s_today_lowest=${stock_info_array[6]}
	s_dealed_stock_num=${stock_info_array[9]}
	s_dealed_stock_cash_num=${stock_info_array[10]}
	s_date=${stock_info_array[31]}
	s_time=${stock_info_array[32]}
	
	#####################################
	#${stock_info_array[11-20] buy1-buy5
	#${stock_info_array[21-30] sale1-sale5
	######################################
				

}

############################################################################
#
# funciton:  print_pre_zero(arg1)
#
# result: add prefix zero for rate
#
############################################################################
function print_pre_zero()
{
	local cmp_value_1=`echo "$1 < 0 && $1 > -1" | bc`
	local cmp_value_2=`echo "$1 >0 && $1 < 1" | bc`
	if [ $cmp_value_1 -eq "1" ]
	then
		local tmp_val=`echo "scale=2;$1 / -1" | bc -l`
		echo "-0$tmp_val"
	elif [ $cmp_value_2 -eq "1" ]
	then
		echo "0$1"
	else
		echo "$1"
	fi
	
}

############################################################################
#
# funciton:  cmp_display(arg1,arg2)
#
# result: print arg1 with color(red or green)
#
############################################################################
function cmp_display()
{
#############################################################################
#  Two methods to compare float:	
#   1. ds=`echo "0" "0" | awk '{if($1>=$2) {print 1;} else {print 0;}}'`
#   2. ds=`echo "$1 >= $2" | bc`
#	echo $ds
#############################################################################
	local cmp_value=`echo "$1 >= $2" | bc -l`
	if [ $cmp_value -eq "0" ]
	then
		echo -e "$COLOR_GREEN $1 $COLOR_RESET"
	else
		echo -e "$COLOR_RED $1 $COLOR_RESET"
	fi
}


############################################################################
#
# funciton:  cmp_display_rate(arg1,arg2)
#
# result: print arg1 with color(red or green) and add prefix zero. 
#
############################################################################
function cmp_display_rate()
{
	local tmp_rate=`echo "($1 - $2) / $2 * 100" | bc -l`
	local cmp_rate=`echo "scale=2;$tmp_rate/1" | bc`

	local cmp_value=`echo "$1 >= $2" | bc`
	
	if [ $cmp_value -eq "0" ]
	then
		echo -e "$COLOR_GREEN $1 ($(print_pre_zero $(echo $1 - $2 | bc -l)) $(print_pre_zero $cmp_rate)%)$COLOR_RESET"
	else
		echo -e "$COLOR_RED $1 (+$(print_pre_zero $(echo $1 - $2 | bc -l)) $(print_pre_zero $cmp_rate)%)$COLOR_RESET"
	fi


}

function display_info()
{
	echo -e "$s_date"
	echo -e "$s_time"
	echo -e "$ITEM_COLOR STOCK: $s_name No. $s_num $COLOR_RESET"
	echo -e "$ITEM_COLOR Last Day Closed Price:$COLOR_RESET $s_lastday_close"
	echo -e "$ITEM_COLOR Today Open Price:$COLOR_RESET $(cmp_display $s_today_open $s_lastday_close)"
	echo -e "$ITEM_COLOR Curren Price:$COLOR_RESET $(cmp_display_rate $s_current_price $s_lastday_close)"
	echo -e "$ITEM_COLOR Highest Price:$COLOR_RESET $(cmp_display $s_today_highest $s_lastday_close)"
	echo -e "$ITEM_COLOR Lowest Price:$COLOR_RESET $(cmp_display $s_today_lowest $s_lastday_close)"
	echo -e "$ITEM_COLOR Dealed Stock Num(per 100):$COLOR_RESET $(expr $s_dealed_stock_num / 100)"
	echo -e "$ITEM_COLOR Dealed Stock Cash Num:$COLOR_RESET $s_dealed_stock_cash_num"
}

function display_hs_index()
{
	eval $(echo $1 | awk '{split($0,array,","); for(i in array) print "hs_info_array["i"]="array[i]}')
	echo -e "$ITEM_COLOR Index:$COLOR_RESET ${hs_info_array[1]}$COLOR_RESET"
	echo -e "$ITEM_COLOR Today Open:$COLOR_RESET $(cmp_display ${hs_info_array[2]} ${hs_info_array[3]})"
	echo -e "$ITEM_COLOR Last CLosed:$COLOR_RESET ${hs_info_array[3]}"
	echo -e "$ITEM_COLOR Curren :$COLOR_RESET $(cmp_display_rate ${hs_info_array[4]} ${hs_info_array[3]})"
	echo -e "$ITEM_COLOR Highest:$COLOR_RESET $(cmp_display ${hs_info_array[5]} ${hs_info_array[3]})"
	echo -e "$ITEM_COLOR Lowest:$COLOR_RESET $(cmp_display ${hs_info_array[6]} ${hs_info_array[3]})"
	


}

function view_hs_index()
{
	sh_info=`curl http://hq.sinajs.cn/list=sh000001 2>/dev/null | sed -n -e 's/var.*=\"//' -e 's/\";$//p'`
	if [ "$sh_info" != "" ];then
		display_hs_index $sh_info
	else
		echo "Exception:Can't find any infomation about $s_num"
	fi
	sz_info=`curl http://hq.sinajs.cn/list=sz399001 2>/dev/null | sed -n -e 's/var.*=\"//' -e 's/\";$//p'`
	if [ "$sz_info" != "" ];then
		display_hs_index $sz_info
	else
		echo "Exception:Can't find any infomation about $s_num"
	fi
	
}

view_hs_index
read_data_file
#trap "ERRTRAP $LINENO" ERR

