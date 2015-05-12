script "unmount" do
		interpreter "bash"
		user "root"
		code <<-EOH
			if grep "wp-content" -qs /proc/mounts; then 
				umount /srv/www/zh_wordpress/current/wp-content
			fi
		EOH
end