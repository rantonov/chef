script "installmemcache" do
		interpreter "bash"
		user "root"
		code <<-EOH
		apt-get install php5-memcache memcached;
		EOH
end
