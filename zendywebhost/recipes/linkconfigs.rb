script "linkconfigs" do
 	interpreter "bash"
 	user "root"
 	code <<-EOH
 			WP_CONTENT=/srv/www/zh_wordpress/current/wp-content;
 			if ! [[ -L "$WP_CONTENT" && -d "$WP_CONTENT" ]]; then
 				rm -rf $WP_CONTENT;
 				ln -s /srv/www/zh_wordpress/shared/content $WP_CONTENT;
 			fi
 	EOH
end		


		
#		link "#{deploy[:deploy_to]}/current/wp-content" do
#			to "/srv/www/zh_wordpress/shared/content"
#			mode "0777"
#			owner "root"
#		end 
