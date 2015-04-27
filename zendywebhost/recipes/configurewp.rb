include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_http'

# Create the Wordpress config file wp-config.php with corresponding values
node[:deploy].each do |app_name, deploy|
	if "#{deploy[:deploy_to]}".include? "wordpress"
		Chef::Log.info("*********** Creating wp-config.php for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/current/wp-config.php" do
			source "wp-config.php.erb"
			mode 0660
			group deploy[:group]

			if platform?("ubuntu")
				owner "www-data"
			elsif platform?("amazon")
				owner "apache"
			end

			variables(
				:database   => (deploy[:database][:database] rescue nil),
				:user       => (deploy[:database][:username] rescue nil),
				:password   => (deploy[:database][:password] rescue nil),
				:host       => (deploy[:database][:host] rescue nil),
				:keys       => (deploy[:salt] rescue nil)
			)
		end #template
		
		
				
		Chef::Log.info("*********** Creating rewrite.conf  for #{deploy[:deploy_to]}...*************")
		template "/etc/apache2/sites-available/zh_wordpress.conf.d/rewrite.conf" do
			source "rewrite.conf.erb"
			mode 0660
			group deploy[:group]
			owner "root"
		end
		
		Chef::Log.info("*********** Creating memcached.conf  for #{deploy[:deploy_to]}...*************")
		template "/etc/memcached.conf" do
			source "memcached.conf.erb"
			mode 0660
			group deploy[:group]
			owner "root"
			
			variables(
				:my_ip_address => (node[:opsworks][:instance][:private_ip] rescue nil)
			)
		end
		
		script "restartmemcached" do
			interpreter "bash"
			user "root"
			code <<-EOH
				service memcached restart;			
			EOH
		end
		
		include_recipe 'zendywebhost::configurememcache'

		
#		link "#{deploy[:deploy_to]}/current/wp-content" do
#			to "/srv/www/zh_wordpress/shared/content"
#			mode "0777"
#			owner "root"
#		end 
		
		script "linkconfigs" do
			interpreter "bash"
			user "root"
			code <<-EOH
					WP_CONTENT=#{deploy[:deploy_to]}/current/wp-content;
					if ! [[ -L "$WP_CONTENT" && -d "$WP_CONTENT" ]]; then
						rm -rf $WP_CONTENT;
						ln -s /srv/www/zh_wordpress/shared/content $WP_CONTENT;
					fi
			EOH
		end		
	end	
end
