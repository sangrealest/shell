Template of php-fpm

Configure php-fpm
 
Uncomment pm.status_path in your php-fpm pool's configuration file

pm.status_path = /php-fpm_status

Configure Nginx
 
Add bellow to your Nginx Configuration:

server {

    listen 800;
    location /php-fpm_status {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

Be noticed that if you use different port of php-fpm_status, please remember to modify the port configuration in php-fpm-check.sh and php-fpm-template.xml

After a restart php-rpm and reload nginx, try this to verify whether it works.
wget http://localhost:800/php-fpm_status
/etc/zabbix/script/php-fpm-check.sh "total processes"
