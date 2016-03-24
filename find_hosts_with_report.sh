#!/bin/bash
shopt -s -o nounset
HostList=${1:?'please inpute host ip address!'}
[ ! -f $HostList ] && echo 'the file not exist' && exit 1
Date=$(date +"%Y%m%d%H%M")
Date_for_man=$(date +"%Y-%m-%d %Hhour %M minutes")
#the counts of ping
pno=2
#path file to save
padir="/var/www/html/pa"
pahtml="$padir/index.html"
pahtml_now="$padir/pa-$Date.html"

#functions

function html_head(){
      [ ! -e $padir ] && mkdir -p $padir
            cat >$pahtml_now<<HEAD
              <html>
                <head>
                  <title>ping alive check result</title>
                    <meta HTTP-EQUIV="Refresh" CONTENT="900">
                      <meta HTTP-EQUIV="Pragma" CONTENT="no-cache">
                        <meta HTTP-EQUIV="Content-type" content="text/html; charset=UTF8">
                          </head>
                            <body bgcolor="white">
                              <div align=center><font size=6><b>***my hosts monitor</b></font></div>
                                <div align=center>check time: $Date_for_man</div>
                                  <p>
                                      <table width="60%" align=center border=3>
                                            <tr>
                                                    <td nowrap>hostname</td>
                                                            <td>IP</td>
                                                                    <td nowrap>min time</td>
                                                                            <td nowrap>max time</td>
                                                                                    <td nowrap>avg time</td>
                                                                                          </tr>
                                                                                          HEAD

}
html_tr(){
      if [ "$1" == "PingError" ]
            then
                    cat<<TR >>$pahtml_now
                        <tr>
                                <td>host</td>
                                        <td>$ip</td>
                                                <td colspan=4><font color=red><b>can't reachable!!!</b></font></td>
                                                    </tr>
                                                    TR
                                                      else
                                                              cat <<TR >>$pahtml_now
                                                                        <tr>
                                                                                <td>host</td>
                                                                                        <td>$ip</td>
                                                                                                <td>$rt_min ms</td>
                                                                                                        <td>$rt_max ms</td>
                                                                                                                <td>$rt_avg ms</td>
                                                                                                                      </tr>
                                                                                                                      TR

                                                                                                                          fi
}
html_end(){
      cat >>$pahtml_now<<END
              </table>
                </body>
                  </html>
                  END
                    ln -sf $pahtml_now $pahtml
}
#the main of the shell

#check up the webpage head
html_head

while read ip
do
  rt_min=
    rt_avg=
      rt_max=
        ping -c $pno -W1 $ip >tmp
          r=$(cat tmp|grep rtt)
    if [ -n "$r" ]
      then
            rt_min=$(echo $r | awk '{print $4}'|awk -F/ '{print $1}')
                  rt_avg=$(echo $r | awk '{print $4}'|awk -F/ '{print $2}')
                        rt_max=$(echo $r | awk '{print $4}'|awk -F/ '{print $3}')
                              html_tr $rt_min $rt_avg $rt_max
                                    
                                 fi
                                   if [ -z $rt_min ]
                                     then
                                         html_tr PingError
                                           fi
                                           done<$HostList
                                           html_end
                                           rm -f tmp
