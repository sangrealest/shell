When using vmstat and iostat, please add bellow crontab job for zabbix
#crontab -u zabbix -e

* * * * * * /etc/zabbix/scripts/zabbix_vmstat_cron.sh
* * * * * * /etc/zabbix/scripts/zabbix_iostat_cron.sh

If you store the temp vmstat|iostat data to other folder than /usr/share/zabbix/data/, please also modify the data folder in zabbix_{vmstat,iostat}_check.sh.
Learned from this site:
https://github.com/jizhang/zabbix-templates/tree/master/iostat and 
https://github.com/zbal/zabbix.
