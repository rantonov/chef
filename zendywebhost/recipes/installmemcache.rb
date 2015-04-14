script "installmemcache" do
		interpreter "bash"
		user "root"
		code <<-EOH
		apt-get -y install php5-memcache memcached;
		EOH
end
