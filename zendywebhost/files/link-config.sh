#/usr/sh
# the Environment variable is one of {dev|test|prod}
ln -s /srv/www/zh_wordpress/current/wp-configs/wp-config_zh_${Environment}.php /srv/www/zh_wordpress/current/wp-config.php
ln -s  /srv/www/zh_wordpress/shared/content /srv/www/zh_wordpress/current/wp-content

