session_save_path=""
Chef::Log.info("********  Instances: #{node[:opsworks][:layers]['php-app'][:instances]} *************")


node[:opsworks][:layers]['php-app'][:instances].each do | instance, conf |
	session_save_path << "tcp://"<<"#{conf[:private_ip]}"<<":11211,"
end
session_save_path=session_save_path.chop #the last comma

Chef::Log.info("*********** memcache session.save_path=#{session_save_path}  *************")

script "installmemcache" do
	interpreter "bash"
	user "root"
	code <<-EOH
		apt-get -y install php5-memcache ;
		echo '*********** configure memcached *************'
		cp /etc/memcached.conf /etc/memcached.conf.orig

		echo '*********** changing server ip *************'
		sed -i "s/127\.0\.0\.1/`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/" /etc/memcached.conf ;

		echo '*********** installing new memcached.conf *************'
		cp /etc/memcached.conf.new /etc/memcached.conf;
		echo '*********** restarting memcached *************'
		service memcached restart;
		
		echo '*********** configure redundancy *************'
		if ! grep "memcache\.allow_failover=1" /etc/php5/mods-available/memcache.ini ;  then
			echo "memcache.allow_failover=1" >> /etc/php5/mods-available/memcache.ini;
			echo memcache.session_redundancy=#{node[:opsworks][:layers]['php-app'][:instances].length+1} >> /etc/php5/mods-available/memcache.ini;
		else
			echo '*********** changing node count *************'
			sed -i "/memcache.session_redundancy/c\  memcache.session_redundancy=#{node[:opsworks][:layers]['php-app'][:instances].length+1}" /etc/php5/mods-available/memcache.ini;
		fi
		
	
		echo '*********** configure php to use memcached for sessions *************'
		if grep "^\ *session.save_path" /etc/php5/apache2/php.ini ; then
			echo '*********** the line exists *************'
			cat /etc/php5/apache2/php.ini | sed "/^\ *session.save_path/c\ session.save_path=\'#{session_save_path}\'" > /etc/php5/apache2/php.ini.new;
		else
			echo '*********** the line is new *************'
			cat /etc/php5/apache2/php.ini |sed "/; The path can be defined as:/c\ session.save_path=\'#{session_save_path}\'" > /etc/php5/apache2/php.ini.new;
		fi
		cp /etc/php5/apache2/php.ini.new /etc/php5/apache2/php.ini;

	
		cat /etc/php5/apache2/php.ini | sed "/session.save_handler/c\  session.save_handler = memcache" > /etc/php5/apache2/php.ini.new;
		cp /etc/php5/apache2/php.ini.new /etc/php5/apache2/php.ini;
				 
	EOH
end
