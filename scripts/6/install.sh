#!/bin/bash
#######################################################
# actvps Script v2.0.4 for CentOS 6
# To install type: 
# curl -sO https://actcms.work/install && bash install
# or
# curl -sO https://actcms.work/scripts/$(rpm -E %centos)/install && bash install
#######################################################
actvps_version="2.0.4"
phpmyadmin_version="4.8.0.1" # Released 2018-04-19. Future version compatible with PHP 5.5 to 7.2 and MySQL 5.5 and newer.
extplorer_version="2.1.10"
script_root="https://actcms.work/scripts"
script_url="https://actcms.work/scripts/6"
low_ram='262144' # 256MB

yum -y install gawk bc wget lsof

clear
printf "=========================================================================\n"
printf "Chung ta se kiem tra cac thong so VPS cua ban de dua ra cai dat hop ly \n"
printf "=========================================================================\n"

cpu_name=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpu_cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpu_freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
server_hdd=$( df -h | awk 'NR==2 {print $2}' )
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`
server_ip=$(curl -s $script_root/ip/)

printf "=========================================================================\n"
printf "Thong so server cua ban nhu sau \n"
printf "=========================================================================\n"
echo "Loai CPU : $cpu_name"
echo "Tong so CPU core : $cpu_cores"
echo "Toc do moi core : $cpu_freq MHz"
echo "Tong dung luong RAM : $server_ram_mb MB"
echo "Tong dung luong swap : $server_swap_mb MB"
echo "Tong dung luong o dia : $server_hdd GB"
echo "IP cua server la : $server_ip"
printf "=========================================================================\n"
printf "=========================================================================\n"

if [ $server_ram_total -lt $low_ram ]; then
	echo -e "Canh bao: dung luong RAM qua thap de cai actvps Script \n (it nhat 256MB) \n"
	echo "huy cai dat..."
	exit
fi
sleep 3

clear
printf "=========================================================================\n"
printf "Chuan bi qua trinh cai dat... \n"
printf "=========================================================================\n"

printf "Ban hay lua chon phien ban PHP muon su dung:\n"
prompt="Nhap vao lua chon cua ban [1-3]: "
php_version="7.1"; # Default PHP 7.1
options=("PHP 7.1" "PHP 7.0" "PHP 5.6")
PS3="$prompt"
select opt in "${options[@]}"; do 

    case "$REPLY" in
    1) php_version="7.1"; break;;
    2) php_version="7.0"; break;;
    3) php_version="5.6"; break;;
    $(( ${#options[@]}+1 )) ) printf "\nHe thong se cai dat PHP 7.1\n"; break;;
    *) printf "Ban nhap sai, he thong cai dat PHP 7.1\n"; break;;
    esac
    
done

printf "\nNhap vao ten mien chinh (non-www hoac www) roi an [ENTER]: " 
read server_name
if [ "$server_name" == "" ]; then
	server_name="actcms.work"
	echo "Ban nhap sai, he thong dung actcms.work lam ten mien chinh"
fi

printf "\nNhap vao port admin roi an [ENTER]: " 
read admin_port
if [ "$admin_port" == "" ] || [ $admin_port == "2222" ] || [ $admin_port -lt 2000 ] || [ $admin_port -gt 9999 ] || [ $(lsof -i -P | grep ":$admin_port " | wc -l) != "0" ]; then
	admin_port=$(date +'%Y')
	echo "Port admin khong phu hop. He thong su dung port mac dinh $admin_port"
	echo
fi

printf "=========================================================================\n"
printf "Hoan tat qua trinh chuan bi... \n"
printf "=========================================================================\n"


rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
fi
setenforce 0

# Install EPEL + Remi Repo
yum -y install epel-release yum-utils
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

# Install Nginx Repo
rpm -Uvh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm

# Install MariaDB Repo 10.0
wget -O /etc/yum.repos.d/MariaDB.repo $script_url/repo/mariadb/$(uname -i)/10

service saslauthd stop
chkconfig saslauthd off

yum -y remove mysql* php* httpd* sendmail* postfix* rsyslog*
yum clean all
yum -y update

clear
printf "=========================================================================\n"
printf "Chuan bi xong, bat dau cai dat server... \n"
printf "=========================================================================\n"
sleep 3

# Install Nginx, PHP-FPM and modules

# Enable Remi Repo
yum-config-manager --enable remi

if [ "$php_version" = "7.1" ]; then
	yum-config-manager --enable remi-php71
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "7.0" ]; then
	yum-config-manager --enable remi-php70
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "5.6" ]; then
	yum-config-manager --enable remi-php56
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli
elif [ "$php_version" = "5.5" ]; then
	yum-config-manager --enable remi-php55
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli
else
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-devel php-cli gcc
fi

# Install MariaDB
yum -y install MariaDB-server MariaDB-client

# Install Others
yum -y install exim syslog-ng syslog-ng-libdbi cronie fail2ban unzip zip nano openssl ntpdate

ntpdate asia.pool.ntp.org
hwclock --systohc

clear
printf "=========================================================================\n"
printf "Cai dat xong, bat dau cau hinh server... \n"
printf "=========================================================================\n"
sleep 3

# Autostart
chkconfig --add nginx
chkconfig --levels 235 nginx on
chkconfig --add php-fpm
chkconfig --levels 235 php-fpm on
chkconfig --add exim
chkconfig --levels 235 exim on
chkconfig --add syslog-ng
chkconfig --levels 235 syslog-ng on
chkconfig --add fail2ban
chkconfig --levels 23 fail2ban on

#service exim start
#service syslog-ng start

mkdir -p /home/$server_name/public_html
mkdir /home/$server_name/private_html
mkdir /home/$server_name/logs
chmod 777 /home/$server_name/logs


mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /var/lib/php/session

wget -q $script_url/html/index.html -O /home/$server_name/public_html/index.html

service nginx start
service php-fpm start
service mysql start

# PHP #
phplowmem='2097152'
check_phplowmem=$(expr $server_ram_mb \< $phplowmem)
max_children=`echo "scale=0;$server_ram_mb*0.4/30" | bc`

if [ "$check_phplowmem" == "1" ]; then
	lessphpmem=y
fi

if [[ "$lessphpmem" = [yY] ]]; then  
	# echo -e "\nCopying php-fpm-min.conf /etc/php-fpm.d/www.conf\n"
	wget -q $script_root/config/php-fpm/php-fpm-min.conf -O /etc/php-fpm.conf
	wget -q $script_root/config/php-fpm/www-min.conf -O /etc/php-fpm.d/www.conf
else
	# echo -e "\nCopying php-fpm.conf /etc/php-fpm.d/www.conf\n"
	wget -q $script_root/config/php-fpm/php-fpm.conf -O /etc/php-fpm.conf
	wget -q $script_root/config/php-fpm/www.conf -O /etc/php-fpm.d/www.conf
fi # lessphpmem

sed -i "s/server_name_here/$server_name/g" /etc/php-fpm.conf
sed -i "s/server_name_here/$server_name/g" /etc/php-fpm.d/www.conf
sed -i "s/max_children_here/$max_children/g" /etc/php-fpm.d/www.conf

# dynamic PHP memory_limit calculation
if [[ "$server_ram_total" -le '262144' ]]; then
	php_memorylimit='48M'
	php_uploadlimit='48M'
	php_realpathlimit='256k'
	php_realpathttl='14400'
elif [[ "$server_ram_total" -gt '262144' && "$server_ram_total" -le '393216' ]]; then
	php_memorylimit='96M'
	php_uploadlimit='96M'
	php_realpathlimit='320k'
	php_realpathttl='21600'
elif [[ "$server_ram_total" -gt '393216' && "$server_ram_total" -le '524288' ]]; then
	php_memorylimit='128M'
	php_uploadlimit='128M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '524288' && "$server_ram_total" -le '1049576' ]]; then
	php_memorylimit='160M'
	php_uploadlimit='160M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '1049576' && "$server_ram_total" -le '2097152' ]]; then
	php_memorylimit='256M'
	php_uploadlimit='256M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '2097152' && "$server_ram_total" -le '3145728' ]]; then
	php_memorylimit='320M'
	php_uploadlimit='320M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '3145728' && "$server_ram_total" -le '4194304' ]]; then
	php_memorylimit='512M'
	php_uploadlimit='512M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '4194304' ]]; then
	php_memorylimit='800M'
	php_uploadlimit='800M'
	php_realpathlimit='640k'
	php_realpathttl='86400'
fi

cat > "/etc/php.d/00-actvps-custom.ini" <<END
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 180
short_open_tag = On
realpath_cache_size = $php_realpathlimit
realpath_cache_ttl = $php_realpathttl
memory_limit = $php_memorylimit
upload_max_filesize = $php_uploadlimit
post_max_size = $php_uploadlimit
expose_php = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = 2000
mysqlnd.net_cmd_buffer_size = 16384
always_populate_raw_post_data=-1
disable_functions=shell_exec
END

# Zend Opcache
opcache_path='opcache.so' #Default for PHP 5.5 and PHP 5.6

if [ "$php_version" = "5.4" ]; then
	cd /usr/local/src
	wget http://pecl.php.net/get/ZendOpcache
	tar xvfz ZendOpcache
	cd zendopcache-7.*
	phpize
	php_config_path=`which php-config`
	./configure --with-php-config=$php_config_path
	make
	make install
	rm -rf /usr/local/src/zendopcache*
	rm -f ZendOpcache
	opcache_path=`find / -name 'opcache.so'`
fi

wget -q https://raw.github.com/amnuts/opcache-gui/master/index.php -O /home/$server_name/private_html/op.php
cat > /etc/php.d/*opcache*.ini <<END
zend_extension=$opcache_path
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=4000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
END

cat > /etc/php.d/opcache-default.blacklist <<END
/home/*/public_html/wp-content/plugins/backwpup/*
/home/*/public_html/wp-content/plugins/duplicator/*
/home/*/public_html/wp-content/plugins/updraftplus/*
/home/$server_name/private_html/
END

service php-fpm restart

# Nginx #
cat > "/etc/nginx/nginx.conf" <<END

user nginx;
worker_processes auto;
worker_rlimit_nofile 260000;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
	worker_connections  2048;
	accept_mutex off;
	accept_mutex_delay 200ms;
	use epoll;
	#multi_accept on;
}

http {
	include       /etc/nginx/mime.types;
	default_type  application/octet-stream;

	log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	              '\$status \$body_bytes_sent "\$http_referer" '
	              '"\$http_user_agent" "\$http_x_forwarded_for"';
		      
	#Disable IFRAME
	add_header X-Frame-Options SAMEORIGIN;
	
	#Prevent Cross-site scripting (XSS) attacks
	add_header X-XSS-Protection "1; mode=block";
	
	#Prevent MIME-sniffing
	add_header X-Content-Type-Options nosniff;
	
	access_log  off;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay off;
	types_hash_max_size 2048;
	server_tokens off;
	server_names_hash_bucket_size 128;
	client_max_body_size 0;
	client_body_buffer_size 256k;
	client_body_in_file_only off;
	client_body_timeout 60s;
	client_header_buffer_size 256k;
	client_header_timeout  20s;
	large_client_header_buffers 8 256k;
	keepalive_timeout 10;
	keepalive_disable msie6;
	reset_timedout_connection on;
	send_timeout 60s;

	gzip on;
	gzip_static on;
	gzip_disable "msie6";
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_types text/plain text/css application/json text/javascript application/javascript text/xml application/xml application/xml+rss;

	include /etc/nginx/conf.d/*.conf;
}
END

cat > "/usr/share/nginx/html/403.html" <<END
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>actvps-nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/usr/share/nginx/html/404.html" <<END
<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>actvps-nginx</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

rm -rf /etc/nginx/conf.d/*
> /etc/nginx/conf.d/default.conf

server_name_alias="www.$server_name"
if [[ $server_name == *www* ]]; then
    server_name_alias=${server_name/www./''}
fi

cat > "/etc/nginx/conf.d/$server_name.conf" <<END
server {
	listen 80;
	
	server_name $server_name_alias;
	rewrite ^(.*) http://$server_name\$1 permanent;
}

server {
	listen 80 default_server;
		
	# access_log off;
	access_log /home/$server_name/logs/access.log;
	# error_log off;
    	error_log /home/$server_name/logs/error.log;
	
    	root /home/$server_name/public_html;
	index index.php index.html index.htm;
    	server_name $server_name;
 
    	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}
	
	# Custom configuration
	include /home/$server_name/public_html/*.conf;
 
    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 1000;
		fastcgi_send_timeout 1000;
		fastcgi_read_timeout 1000;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    	}
	
	location /nginx_status {
  		stub_status on;
  		access_log   off;
		allow 127.0.0.1;
		allow $server_ip;
		deny all;
	}
	
	location /php_status {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
		include /etc/nginx/fastcgi_params;
		allow 127.0.0.1;
		allow $server_ip;
		deny all;
    	}
	
	# Disable .htaccess and other hidden files
	location ~ /\.(?!well-known).* {
		deny all;
		access_log off;
		log_not_found off;
	}
	
        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }
	
	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}
	
	location ~* \.(3gp|gif|jpg|jpeg|png|ico|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso|eot|svg|ttf|woff)$ {
	        gzip_static off;
		add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }

        location ~* \.(txt|js|css)$ {
	        add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }
}

server {
	listen $admin_port;
	
 	access_log off;
	log_not_found off;
 	error_log /home/$server_name/logs/nginx_error.log;
	
    	root /home/$server_name/private_html;
	index index.php index.html index.htm;
    	server_name $server_name;
 
	auth_basic "Restricted";
	auth_basic_user_file /home/$server_name/private_html/actvps/.htpasswd;
	
	location / {
		autoindex on;
		try_files \$uri \$uri/ /index.php;
	}
	
    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 1000;
		fastcgi_send_timeout 1000;
		fastcgi_read_timeout 1000;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    	}
	
	location ~ /\. {
		deny all;
	}
}
END

cat >> "/etc/security/limits.conf" <<END
* soft nofile 262144
* hard nofile 262144
nginx soft nofile 262144
nginx hard nofile 262144
nobody soft nofile 262144
nobody hard nofile 262144
root soft nofile 262144
root hard nofile 262144
END

ulimit -n 262144

service nginx restart

# MariaDB #
# set /etc/my.cnf templates from Centmin Mod
cp /etc/my.cnf /etc/my.cnf-original

if [[ "$(expr $server_ram_total \<= 2099000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-min.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10-min.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \> 2100001)" = "1" && "$(expr $server_ram_total \<= 4190000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 4190001)" = "1" && "$(expr $server_ram_total \<= 8199999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-4gb.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10-4gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 8200000)" = "1" && "$(expr $server_ram_total \<= 15999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-8gb.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10-8gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 16000000)" = "1" && "$(expr $server_ram_total \<= 31999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-16gb.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10-16gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 32000000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-32gb.cnf file to /etc/my.cnf\n"
	wget -q $script_root/config/mysql/my-mdb10-32gb.cnf -O /etc/my.cnf
fi

sed -i "s/server_name_here/$server_name/g" /etc/my.cnf

rm -f /var/lib/mysql/ib_logfile0
rm -f /var/lib/mysql/ib_logfile1
rm -f /var/lib/mysql/ibdata1

clear
printf "=========================================================================\n"
printf "Thiet lap co ban cho MariaDB ... \n"
printf "=========================================================================\n"
# Random password for MySQL root account
root_password=`date |md5sum |cut -c '14-30'`
sleep 1
# Random password for MySQL admin account
admin_password=`date |md5sum |cut -c '14-30'`
'/usr/bin/mysqladmin' -u root password "$root_password"
mysql -u root -p"$root_password" -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' IDENTIFIED BY '$admin_password' WITH GRANT OPTION;"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost')"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$root_password" -e "DROP User '';"
mysql -u root -p"$root_password" -e "DROP DATABASE test"
mysql -u root -p"$root_password" -e "FLUSH PRIVILEGES"

cat > "/root/.my.cnf" <<END
[client]
user=root
password=$root_password
END
chmod 600 /root/.my.cnf

# Fix MariaDB 10
service mysql stop

wget -q $script_root/config/mysql/mariadb10_3tables.sql

rm -rf /var/lib/mysql/mysql/gtid_slave_pos.ibd
rm -rf /var/lib/mysql/mysql/innodb_table_stats.ibd
rm -rf /var/lib/mysql/mysql/innodb_index_stats.ibd

service mysql start

mysql -e "ALTER TABLE mysql.gtid_slave_pos DISCARD TABLESPACE;" 2> /dev/null
mysql -e "ALTER TABLE mysql.innodb_table_stats DISCARD TABLESPACE;" 2> /dev/null
mysql -e "ALTER TABLE mysql.innodb_index_stats DISCARD TABLESPACE;" 2> /dev/null

mysql mysql < mariadb10_3tables.sql

service mysql restart
mysql_upgrade --force mysql
rm -f mariadb10_3tables.sql

if [ "$1" = "wordpress" ]; then
	clear
	printf "=========================================================================\n"
	printf "Cai dat WordPress... \n"
	printf "=========================================================================\n"
	cd /home/$server_name/public_html/
	rm -f index.html
	# Generate wordpress database
	wordpress_password=`date |md5sum |cut -c '1-15'`
	secure_table_prefix=`date |md5sum |cut -c '1-5'`
	mysql -u root -p"$root_password" -e "CREATE DATABASE wordpress;GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost IDENTIFIED BY '$wordpress_password';FLUSH PRIVILEGES;"
	
	# Download latest WordPress and uncompress
	wget https://wordpress.org/latest.tar.gz
	tar zxf latest.tar.gz
	mv wordpress/* ./

	# Grab Salt Keys
	wget -O /tmp/wp.keys https://api.wordpress.org/secret-key/1.1/salt/

	# Butcher our wp-config.php file
	sed -e "s/database_name_here/wordpress/" -e "s/username_here/wordpress/" -e "s/password_here/"$wordpress_password"/"  -e "s/wp_/wp_"$secure_table_prefix"_/" wp-config-sample.php > wp-config.php
	sed -i '/#@-/r /tmp/wp.keys' wp-config.php
	sed -i "/#@+/,/#@-/d" wp-config.php

	# Tidy up
	rm -rf wordpress latest.tar.gz /tmp/wp.keys wp wp-config-sample.php
fi

clear
printf "=========================================================================\n"
printf "Hoan tat qua trinh cau hinh... \n"
printf "=========================================================================\n"
# actvps Script Admin
cd /home/$server_name/private_html/
wget -q $script_url/package/administrator.zip
unzip -q administrator.zip && rm -f administrator.zip
mv -f administrator/* .
rm -rf administrator
printf "admin:$(openssl passwd -apr1 $admin_password)\n" > /home/$server_name/private_html/actvps/.htpasswd
sed -i "s/rootpassword/$root_password/g" /home/$server_name/private_html/actvps/SQLManager.php

# Server Info
mkdir /home/$server_name/private_html/serverinfo/
cd /home/$server_name/private_html/serverinfo/
wget -q $script_url/package/serverinfo.zip
unzip -q serverinfo.zip && rm -f serverinfo.zip

# phpMyAdmin
mkdir /home/$server_name/private_html/phpmyadmin/
cd /home/$server_name/private_html/phpmyadmin/
wget --no-check-certificate -q https://files.phpmyadmin.net/phpMyAdmin/$phpmyadmin_version/phpMyAdmin-$phpmyadmin_version-english.zip
unzip -q phpMyAdmin-$phpmyadmin_version-english.zip
mv -f phpMyAdmin-$phpmyadmin_version-english/* .
rm -rf phpMyAdmin-$phpmyadmin_version-english*

# eXtplorer File Manager
mkdir /home/$server_name/private_html/filemanager/
cd /home/$server_name/private_html/filemanager/
wget --no-check-certificate -q https://extplorer.net/attachments/download/74/eXtplorer_$extplorer_version.zip # Note ID 74
unzip -q eXtplorer_$extplorer_version.zip && rm -f eXtplorer_$extplorer_version.zip
cat > "/home/$server_name/private_html/filemanager/config/.htusers.php" <<END
<?php
        // ensure this file is being included by a parent file
        if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
        \$GLOBALS["users"]=array(
        array('admin','$(echo -n "$admin_password" | md5sum | awk '{print $1}')','/home','http://localhost','1','','7',1),
);
?>
END

# Log Rotation
cat > "/etc/logrotate.d/nginx" <<END
/home/*/logs/access.log /home/*/logs/error.log /home/*/logs/nginx_error.log {
	create 640 nginx nginx
        daily
        missingok
        rotate 5
        maxage 7
        compress
        delaycompress
        notifempty
        sharedscripts
        postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
        endscript
}
END
cat > "/etc/logrotate.d/php-fpm" <<END
/home/*/logs/php-fpm*.log {
        daily
        compress
        maxage 7
        missingok
        notifempty
        sharedscripts
        delaycompress
        postrotate
            /bin/kill -SIGUSR1 \`cat /var/run/php-fpm/php-fpm.pid 2>/dev/null\` 2>/dev/null || true
        endscript
}
END
cat > "/etc/logrotate.d/mysql" <<END
/home/*/logs/mysql*.log {
        create 640 mysql mysql
        notifempty
        daily
        rotate 3
        maxage 7
        missingok
        compress
        postrotate
        # just if mysqld is really running
        if test -x /usr/bin/mysqladmin && \
           /usr/bin/mysqladmin ping &>/dev/null
        then
           /usr/bin/mysqladmin flush-logs
        fi
        endscript
}
END

# Change port SSH
sed -i 's/#Port 22/Port 2222/g' /etc/ssh/sshd_config

cat > "/etc/fail2ban/jail.local" <<END
[sshd]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=2222, protocol=tcp]
logpath  = /var/log/secure
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
action = iptables[name=NoAuthFailures, port=$admin_port, protocol=tcp]
logpath = /home/$server_name/logs/nginx_error.log
maxretry = 3
bantime = 3600
END

service fail2ban start

# Open port
if [ -f /etc/sysconfig/iptables ]; then
service iptables start
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 25 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 465 -j ACCEPT
iptables -I INPUT -p tcp --dport 587 -j ACCEPT
iptables -I INPUT -p tcp --dport $admin_port -j ACCEPT
iptables -I INPUT -p tcp --dport 2222 -j ACCEPT
service iptables save
fi

mkdir -p /var/lib/php/session
chown -R nginx:nginx /var/lib/php
chown nginx:nginx /home/$server_name
chown -R nginx:nginx /home/*/public_html
chown -R nginx:nginx /home/*/private_html

rm -f /root/install*
echo -n "cd /home" >> /root/.bashrc

mkdir -p /etc/actvps/

cat > "/etc/actvps/scripts.conf" <<END
actvps_version="$actvps_version"
server_name="$server_name"
server_ip="$server_ip"
admin_port="$admin_port"
script_url="$script_url"
mariadb_root_password="$root_password"
END
chmod 600 /etc/actvps/scripts.conf

clear
printf "=========================================================================\n"
printf "Cau hinh hoan tat, bat dau them menu actvps, nhanh thoi... \n"
printf "=========================================================================\n"
wget -q $script_url/actvps -O /bin/actvps && chmod +x /bin/actvps
mkdir -p /etc/actvps/menu/
cd /etc/actvps/menu/
wget -q $script_url/component/menu.zip
unzip -q menu.zip && rm -f menu.zip
chmod +x /etc/actvps/menu/*

clear
cat > "/root/actvps-script.txt" <<END
=========================================================================
                           MANAGE VPS INFORMATION                        
=========================================================================
Lenh truy cap menu actvps Script: actvps

Domain chinh: http://$server_name/ hoac http://$server_ip/

actvps Script Admin:	http://$server_name:$admin_port/ hoac http://$server_ip:$admin_port/
File Manager:		http://$server_name:$admin_port/filemanager/ hoac http://$server_ip:$admin_port/filemanager/
phpMyAdmin:		http://$server_name:$admin_port/phpmyadmin/ hoac http://$server_ip:$admin_port/phpmyadmin/
Server Info:		http://$server_name:$admin_port/serverinfo/ hoac http://$server_ip:$admin_port/serverinfo/
PHP OPcache:		http://$server_name:$admin_port/op.php hoac http://$server_ip:$admin_port/op.php

Thong tin dang nhap mac dinh cho tat ca tool:
Username: admin
Password: $admin_password

Neu can ho tro, cac ban hay truy cap https://actcms.work/script/
END

chmod 600 /root/actvps-script.txt

if [ "$1" = "wordpress" ]; then
	printf "=========================================================================\n"
	printf "Hoan tat qua trinh cai dat actvps Script + WordPress! \n"
	printf "=========================================================================\n"
	printf "Tiep theo ban hay truy cap http://$server_name \n hoac http://$server_ip de cau hinh WordPress \n"
else
	printf "=========================================================================\n"
	printf "Scripts actvps da hoan tat qua trinh cai dat... \n"
	printf "=========================================================================\n"
	printf "Sau day la thong tin server moi cua ban, hay doc can than va luu giu lai\n"
	printf "de su dung sau nay:\n\n"
	printf "=========================================================================\n"
	printf "Domain chinh: http://$server_name/ hoac http://$server_ip/\n"
fi

printf "=========================================================================\n"
printf "actvps Script Admin: http://$server_name:$admin_port/ \n hoac http://$server_ip:$admin_port/\n\n"
printf "File Manager: http://$server_name:$admin_port/filemanager/ \n hoac http://$server_ip:$admin_port/filemanager/\n\n"
printf "phpMyAdmin: http://$server_name:$admin_port/phpmyadmin/ \n hoac http://$server_ip:$admin_port/phpmyadmin/\n\n"
printf "Server Info: http://$server_name:$admin_port/serverinfo/ \n hoac http://$server_ip:$admin_port/serverinfo/\n\n"
printf "PHP OPcache: http://$server_name:$admin_port/op.php \n hoac http://$server_ip:$admin_port/op.php\n"
printf "=========================================================================\n"
printf "Thong tin dang nhap mac dinh cho tat ca tool:\n"
printf " Username: admin\n"
printf " Password: $admin_password\n"
printf "=========================================================================\n"
printf "Thong tin quan ly duoc luu tai: /root/actvps-script.txt \n"
printf "=========================================================================\n"
printf "***Luu y: Port dang nhap SSH da duoc doi tu 22 sang 2222 de bao mat VPS\n"
printf "=========================================================================\n"
printf "De quan ly server, ban hay dung lenh \"actvps\" khi ket noi SSH.\n"
printf "Neu can ho tro, cac ban hay truy cap https://actcms.work/script/\n"
printf "=========================================================================\n"
printf "Server se tu dong khoi dong lai sau 3s nua.... \n\n"
sleep 3
reboot
exit
