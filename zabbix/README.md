When using vmstat and iostat, please add bellow crontab job for zabbix
#crontab -u zabbix -e

* * * * * * /etc/zabbix/scripts/zabbix_vmstat_cron.sh
* * * * * * /etc/zabbix/scripts/zabbix_iostat_cron.sh

Learned from this site:
https://github.com/jizhang/zabbix-templates/tree/master/iostat and 
https://github.com/zbal/zabbix.
