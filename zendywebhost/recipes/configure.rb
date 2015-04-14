# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the config file wp-config.php and links things.


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
		end
	elsif "#{deploy[:deploy_to]}".include? "website"
		Chef::Log.info("*********** Creating proxy config for #{deploy[:deploy_to]}...*************")
		template "/etc/apache2/sites-available/zh_website.conf.d/localproxy.conf" do
			source "localproxy.conf.erb"
			mode 0660
			group deploy[:group]
			owner "root"

			variables(
				:proxy_base_url => (deploy[:proxy][:base_url] rescue nil)
			)
		end

		Chef::Log.info("*********** Creating application.config  for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/current/application/config/application.config.php" do
			source "application.config.php.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:api_url => (deploy[:api][:url] rescue nil),
				:environment => (deploy[:zhenvironment] rescue nil),
				:admin_url => (deploy[:admin_site] rescue nil),
				:s3_bucket => (deploy[:s3_bucket] rescue nil)
			)
		end

	elsif "#{deploy[:deploy_to]}".include? "admin"	
		Chef::Log.info("*********** Creating settings.db.php  for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/current/app/data/setting.db.php" do
			source "setting.db.php.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:platformsoa_host => (deploy[:api][:host] rescue nil),
				:site_url => (deploy[:main_site] rescue nil),
				:s3_bucket => (deploy[:s3_bucket] rescue nil)
			)
		end
		
	end
	
	if "#{deploy[:deploy_to]}".include? "wordpress"

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
	elsif "#{deploy[:deploy_to]}".include? "website"
		script "configurewebsite" do	
			interpreter "bash"
			user "root"
			code <<-EOH
					sed -i "/HessianServiceUrl/c\    define('HessianServiceUrl', 'http://internal-dev-api-lb-75921361.us-west-2.elb.amazonaws.com:8080/zendyhealthapi/services');" #{deploy[:deploy_to]}/current/application/config/application.config.php ;
			EOH
		end
	elsif "#{deploy[:deploy_to]}".include? "admin"
		script "configureadmin" do
			interpreter "bash"
			user "root"
			code <<-EOH
					sed -i "/HessianServiceUrl/c\\$this->AddRow('HessianServiceUrl', 'http://internal-dev-api-lb-75921361.us-west-2.elb.amazonaws.com:8080/zendyhealthapi/services');" #{deploy[:deploy_to]}/current/app/data/setting.db.php ;
			EOH
		end	
	end
end

