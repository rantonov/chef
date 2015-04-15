session_save_path="\'"
Chef::Log.info("********  Instances: #{node[:opsworks][:layers]['php-app'][:instances]} *************")


node[:opsworks][:layers]['php-app'][:instances].each do | instance, conf |
	session_save_path << "tcp://"<<"#{conf[:private_ip]}"<<":11211,"
end
session_save_path=session_save_path.chop<<"\'" #the last comma

Chef::Log.info("*********** memcache session.save_path=#{session_save_path}  *************")

script "installmemcache" do
	interpreter "bash"
	user "root"
	code <<-EOH
		apt-get -y install php5-memcache memcached;
		# configure memcached
		# change the server ip
		cat /etc/memcached.conf > memcached.conf.orig
		cat /etc/memcached.conf  | sed "s/127\.0\.0\.1/`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/" > /etc/memcached.conf.new;
		cp /etc/memcached.conf.new /etc/memcached.conf;
		service memcached restart;
		
		#configure php to use memcached for sessions
		sed -i "/session.save_handler/c\  session.save_handler = memcache" /etc/php5/apache2/php.ini;
		if grep "^\ *session.save_path" /etc/php5/apache2/php.ini ; then
		# the line exists
			sed -i "/^session.save_path/c\ session.save_path=#{session_save_path}" /etc/php5/apache2/php.ini;
		else
		#this is a new def
			sed -i "/^;.*session.save_path = \"N;\/path/c\ session.save_path=#{session_save_path}" /etc/php5/apache2/php.ini;
		fi

		#configure redundancy 
		if ! grep "memcache\.allow_failover=1" /etc/php5/mods-available/memcache.ini ;  then
			echo "memcache.allow_failover=1" >> /etc/php5/mods-available/memcache.ini;
			echo memcache.session_redundancy=#{node[:opsworks][:layers]['php-app'][:instances].length+1} >> /etc/php5/mods-available/memcache.ini;
		else
			sed -i "/memcache.session_redundancy/c\  memcache.session_redundancy=#{node[:opsworks][:layers]['php-app'][:instances].length+1}" /etc/php5/mods-available/memcache.ini;
		fi
		
	EOH
end
