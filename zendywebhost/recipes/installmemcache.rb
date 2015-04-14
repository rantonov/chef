script "installmemcache" do
		interpreter "bash"
		user "root"
		code <<-EOH
		apt-get php5-memcache memcached;
		EOH
end
