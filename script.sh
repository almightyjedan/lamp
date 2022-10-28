#!/bin/bash

echo "-------------------------------------------------------------------------------------------
-------------------------------MAKE SURE YOU HAVE AN INTERNET------------------------------
---------------------------------THIS SCRIPT MADE BY JEDAN---------------------------------
---------------------------------------JUST FOR FUN!---------------------------------------
------------------------------------DO NOT USE FOR EXAM!-----------------------------------
-----------------------------------USE AT YOUR OWN RISK!-----------------------------------
-------------------------------------------------------------------------------------------"

if [ -f /etc/lsb-release ]; then
  . /etc/lsb-release
  OS=$DISTRIB_ID
  VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
  OS=Debian # XXX or Ubuntu??
  VER=$(cat /etc/debian_version)
else
  OS=$(uname -s)
  VER=$(uname -r)
fi

if [[ !$OS =~ ^(Debian)$ ]]; then
  echo -e "ERROR: This install script does not support this distro, only Debian supported"
  exit 1
fi

if [ $OS = "Debian" ] && [[ $VER =~ ^10.* ]]; then
    echo 'deb http://repo.antix.or.id/debian/ buster main contrib non-free
deb http://repo.antix.or.id/debian/ buster-updates main contrib non-free
deb http://repo.antix.or.id/debian-security/ buster/updates main contrib non-free'>/etc/apt/sources.list
fi

if [ $OS = "Debian" ] && [[ $VER =~ ^11.* ]]; then
    echo 'deb http://repo.antix.or.id/debian/ bullseye main contrib non-free
deb http://repo.antix.or.id/debian/ bullseye-updates main contrib non-free
deb http://repo.antix.or.id/debian-security/ bullseye-security main contrib non-free'>/etc/apt/sources.list
fi



sleep 1
echo "INSTALLING WILL NOW BEGIN IN 5"
sleep 1
echo "INSTALLING WILL NOW BEGIN IN 4"
sleep 1
echo "INSTALLING WILL NOW BEGIN IN 3"
sleep 1
echo "INSTALLING WILL NOW BEGIN IN 2"
sleep 1
echo "INSTALLING WILL NOW BEGIN IN 1"
sleep 2

read -p "Enter IP CCTV: " ip_cctv

read -p "Enter IP VOIP: " ip_voip

echo "----------------------------------Configuring DNS Server-----------------------------------"
sleep 2

DEBIAN_FRONTEND=noninteractive apt-get update < /dev/null > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -qq unzip bind9 bind9utils dnsutils resolvconf -y< /dev/null > /dev/null

read -p "DNS Forwarder Name: " forwarder
touch /etc/bind/db.$forwarder

read -p "DNS Reverse Name: " reverse

touch /etc/bind/db.$reverse

read -p "Enter DNS Name: " dns

ip_debian=$(ip -4 -o addr | egrep 'enp0s3|ens' | awk '{print $4}' | cut -d '/' -f 1)
first_debian=$(echo $ip_debian | cut -d '.' -f 1)
addr_arpa=$(echo $ip_debian | awk -F. '{print $4"."$3"."$2"."$1}' | cut -d '.' -f 2-4)
rev_debian=$(echo $ip_debian | awk -F. '{print $4"."$3"."$2"."$1}' | cut -d '.' -f 1)
rev_voip=$(echo $ip_voip | awk -F. '{print $4"."$3"."$2"."$1}' | cut -d '.' -f 1)
rev_cctv=$(echo $ip_cctv | awk -F. '{print $4"."$3"."$2"."$1}' | cut -d '.' -f 1)
net_debian=$(echo $ip_debian | awk -F. '{print $1"."$2"."$3"."0"/"24}')
host_debian=$(cat /proc/sys/kernel/hostname)

sleep 2
echo ';
; BIND data file for local loopback interface
;
$TTL	604800
@	IN	SOA	'$dns'. root.'$dns'. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	'$dns'.
@	IN	A	'$ip_debian'
mail	IN	A	'$ip_debian'
cacti	IN	A	'$ip_debian'
php	IN	A	'$ip_debian'
cctv	IN	A	'$ip_cctv'
voip	IN	A	'$ip_voip'
'$dns'.	IN	MX 10	mail' >/etc/bind/db.$forwarder

echo ';
; BIND reverse data file for local loopback interface
;
$TTL	604800
@	IN	SOA	'$dns'. root.'$dns'. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	'$dns'.
'$rev_debian'	IN	PTR	'$dns'.
'$rev_debian'	IN	PTR	php.'$dns'.
'$rev_debian'	IN	PTR	mail.'$dns'.
'$rev_debian'	IN	PTR	cacti.'$dns'.
'$rev_cctv'	IN	PTR	cctv.'$dns'.
'$rev_voip'	IN	PTR	voip.'$dns'.'>/etc/bind/db.$reverse

echo 'zone "'$dns'" {
	type master;
	file "/etc/bind/db.'$forwarder'";
};
zone "'$addr_arpa'.in-addr.arpa" {
	type master;
	file "/etc/bind/db.'$reverse'";
};'>/etc/bind/named.conf.local

echo "nameserver $ip_debian
nameserver 8.8.8.8
nameserver 8.8.4.4">/etc/resolvconf/resolv.conf.d/head

resolvconf -u
systemctl restart resolvconf.service && systemctl restart bind9

echo "---------------------Done Configuring DNS, Now Configuring PHPMyAdmin----------------------"
sleep 2


if [ $OS = "Debian" ] && [[ $VER =~ ^10.* ]]; then
echo "------------------------Installing Important Package For Debian 10--------------------------"
	DEBIAN_FRONTEND=noninteractive apt-get install -qq -y php7.3-bz2 php7.3-cli php7.3-common php7.3-curl php7.3-gd php7.3-gmp php7.3-intl php7.3-json php7.3-ldap php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-pspell php7.3-readline php7.3-snmp php7.3-xml php7.3-zip php7.3-xmlrpc php7.3-soap python3 < /dev/null > /dev/null
fi
DEBIAN_FRONTEND=noninteractive apt-get install -qq -y mariadb-server < /dev/null > /dev/null

echo "-------------------------------------------------------------------------------------------
----------------------------------------!ATENTION!-----------------------------------------
-----------------------------!This User Is For All Databases!------------------------------
-------------------------!MAKE SURE YOU DON'T FORGET THE USERNAME!-------------------------
-------------------------------------------------------------------------------------------"
sleep 2
read -p "Create User Database: " user_sql
read -p "Password For User Database: " paswd_sql
mariadb -e "CREATE OR REPLACE DATABASE phpmyadmin;"
mariadb -e "CREATE OR REPLACE DATABASE wordpress;"
mariadb -e "CREATE OR REPLACE DATABASE cacti;"
mariadb -e "CREATE OR REPLACE DATABASE roundcube;"
mariadb -e "CREATE OR REPLACE USER '$user_sql'@'localhost' identified by '$paswd_sql';"
mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '$user_sql'@'localhost' identified by '$paswd_sql';"
mariadb -e "FLUSH PRIVILEGES;"

unzip -q file/phpMyAdmin-5.2.0-all-languages.zip -d /var/www/html
mv /var/www/html/phpMyAdmin-5.2.0-all-languages /var/www/html/phpmyadmin
cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php

read -p "PHP Vhost Name: " vhost_php

touch /etc/apache2/sites-available/$vhost_php.conf

echo '<VirtualHost *:80>
    ServerName php.'$dns'
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/phpmyadmin
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/$vhost_php.conf

a2ensite $vhost_php.conf
mkdir -p /var/www/html/phpmyadmin/tmp
chown www-data:www-data -R /var/www/html/phpmyadmin
systemctl reload apache2
systemctl restart apache2

echo "------------------Done Configuring PHPMyAdmin, Now Configuring WordPress-------------------"

sleep 2
unzip -q file/wordpress-6.0.3.zip -d /var/www/
touch /var/www/wordpress/wp-config.php

tab='$table_prefix'
touch /var/www/wordpress/wp-config.php
echo "<?php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', '$user_sql' );
define( 'DB_PASSWORD', '$paswd_sql' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
$tab = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';">/var/www/wordpress/wp-config.php

read -p "WordPress Vhost Name: " vhost_wp

touch /etc/apache2/sites-available/$vhost_wp.conf

echo '<VirtualHost *:80>
    ServerName '$dns'
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/wordpress
    Alias /phpmyadmin /var/www/html/phpmyadmin
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/$vhost_wp.conf

a2ensite $vhost_wp.conf
systemctl reload apache2
systemctl restart apache2

echo "------------------Done Configuring WordPress, Now Configuring Mail Server------------------"

DEBIAN_FRONTEND=noninteractive apt-get install dovecot-imapd postfix roundcube -y< /dev/null > /dev/null

echo 'mail_location = maildir:~/Maildir
namespace inbox {
inbox = yes
}
mail_privileged_group = mail
protocol !indexer-worker {
}'>/etc/dovecot/conf.d/10-mail.conf

maildirmake.dovecot /etc/skel/Maildir

myhostname='$myhostname'
mail_name='$mail_name'
data_directory='${data_directory}'

echo 'smtpd_banner = '$myhostname' ESMTP '$mail_name' (Debian/GNU)
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:'$data_directory'/smtpd_scache
smtp_tls_session_cache_database = btree:'$data_directory'/smtp_scache
smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination
myhostname = '$host_debian'
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = '$dns', '$myhostname', localhost
relayhost = 
mynetworks = '$net_debian', 0.0.0.0/0
mailbox_size_limit = 0
recipient_delimiter = 
inet_interfaces = loopback-only
default_transport = error
relay_transport = error
inet_protocols = ipv4
home_mailbox = Maildir/'>/etc/postfix/main.cf

dpkg-reconfigure postfix

systemctl restart postfix

dpkg-reconfigure roundcube-core

config='$config'
default_root='"/etc/roundcube/debian-db-roundcube.php"'

echo "<?php
$config = array();
include_once($default_root);
$config['default_host'] = array('$dns');
$config['smtp_server'] = 'localhost';
$config['smtp_port'] = 25;
$config['smtp_user'] = '';
$config['smtp_pass'] = '';
$config['support_url'] = '';
$config['plugins'] = array(
);
$config['skin'] = 'larry';
$config['enable_spellcheck'] = false;
$config['language'] = 'en_US';">/etc/roundcube/config.inc.php

read -p "Mail Server Vhost Name: " vhost_mail

touch /etc/apache2/sites-available/$vhost_mail.conf

echo '<VirtualHost *:80>
    ServerName mail.'$dns'
    ServerAdmin webmaster@localhost
    DocumentRoot /var/lib/roundcube
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/$vhost_mail.conf

a2ensite $vhost_mail.conf
systemctl reload apache2
systemctl restart apache2

echo "Add Another User?"
select yn in "Yes" "No"; do
case $yn in
        Yes )
        read -p "Name? " new_user
adduser -q --gecos "" $new_user
echo "
Add Another User?
1) Yes
2) No"
        ;;

        No )
        echo "Okey, Exiting..."
        break
        ;;
esac
done

sleep 2

echo "-----------Done Configuring Mail Server, Now Configuring Cacti Monitoring Server-----------"

DEBIAN_FRONTEND=noninteractive apt-get -qq -y install cacti snmp snmpd < /dev/null > /dev/null

read -p "Cacti Monitorting Server Vhost Name: " vhost_cacti

touch /etc/apache2/sites-available/$vhost_cacti.conf

echo '<VirtualHost *:80>
    ServerName cacti.'$dns'
    ServerAdmin webmaster@localhost
    DocumentRoot /usr/share/cacti/site
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>' > /etc/apache2/sites-available/$vhost_cacti.conf

mariadb -u root cacti -e "update user_auth set password=md5('$paswd_sql') where username='admin';"

a2ensite $vhost_cacti.conf
systemctl reload apache2
systemctl restart apache2

echo ""

echo "-------------------------------------------------------------------------------------------
--------------------------REMINDER FOR CACTI, LOGIN USE ADMIN!-----------------------------
----------------------------------------ALL DONE :)----------------------------------------
-----------------------------------HIGHLY RECOMMENDED--------------------------------------
----------------------------OR EVEN MUST RESTART THE SYSTEM--------------------------------
-----------------------------TO MAKE SURE EVERYTHING WORKS---------------------------------
-------------------------------------------------------------------------------------------"

echo "Reebot Now?"
select yn in "Yes" "No"; do
case $yn in
        Yes )
        reboot
        ;;

        No )
        echo "-----------------------------------------ENJOY :)------------------------------------------"
        break
        ;;
esac
done
