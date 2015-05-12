script "mountcontent" do
		interpreter "bash"
		user "root"
		code <<-EOH
			if ! grep "wp-content" -qs /proc/mounts; then 
				apt-get -y install nfs-common;
				mkdir -p /srv/www/zh_wordpress/shared/content;
				mount -t nfs #{node[:deploy][:zh_wordpress][:nfs][:url]}  /srv/www/zh_wordpress/current/wp-content
				chmod -R 777 /srv/www/zh_wordpress/shared/content/*

			fi
		EOH
end


		
#		link "#{deploy[:deploy_to]}/current/wp-content" do
#			to "/srv/www/zh_wordpress/shared/content"
#			mode "0777"
#			owner "root"
#		end 

# script "linkconfigs" do
# 	interpreter "bash"
# 	user "root"
# 	code <<-EOH
# 			WP_CONTENT=/srv/www/zh_wordpress/current/wp-content;
# 			if ! [[ -L "$WP_CONTENT" && -d "$WP_CONTENT" ]]; then
# 				rm -rf $WP_CONTENT;
# 				ln -s /srv/www/zh_wordpress/shared/content $WP_CONTENT;
# 			fi
# 	EOH
# end		
