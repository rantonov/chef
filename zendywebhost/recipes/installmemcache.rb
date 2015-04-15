script "variousfiles" do
	interpreter "bash"
	user "root"
	code <<-EOH
		apt-get -y install php5-memcache memcached;
		# configure memcached
		cat /etc/memcached.conf  | sed "s/127\.0\.0\.1/`ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`/" > /etc/memcached.conf.new;
		mv /etc/memcached.conf.new /etc/memcached.conf;
		service memcached restart;
		echo "memcache.allow_failover=1" >> /etc/php5/mods-available/memcache.ini;
		echo memcache.session_redundancy=#{node[:opsworks][:layers]['php-app'][:instances].length+1} >> /etc/php5/mods-available/memcache.ini;
	EOH
end
