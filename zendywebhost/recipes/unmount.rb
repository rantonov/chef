script "unmount" do
		interpreter "bash"
		user "root"
		code <<-EOH
			if grep "wp-content" -qs /proc/mounts; then 
				umount /srv/www/zh_wordpress/shared/content
			fi
		EOH
end