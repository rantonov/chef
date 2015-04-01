#/usr/sh
yum -y install nfs-utils
mkdir -p /srv/www/zh_wordpress/shared/content
mount -t nfs 10.0.1.16:/usr/share/nas/wp-content  /srv/www/zh_wordpress/shared/content
