script "mountcontent" do
		interpreter "bash"
		user "root"
		code <<-EOH
				mkdir -p /srv/www/zh_wordpress/shared/content;
				mount -t nfs 10.0.1.16:/usr/share/nas/wp-content  /srv/www/zh_wordpress/shared/content
		EOH
end
