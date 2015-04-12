script "mountcontent" do
		interpreter "bash"
		user "root"
		code <<-EOH
		apt-get install nfs-kernel-server;
			if ! grep "wp-content" -qs /proc/mounts; then 
				mkdir -p /srv/www/zh_wordpress/shared/content;
				mount -t nfs 10.0.1.16:/usr/share/nas/wp-content  /srv/www/zh_wordpress/shared/content
			fi
		EOH
end
