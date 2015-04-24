include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_http'

# Create the Wordpress config file wp-config.php with corresponding values
node[:deploy].each do |app_name, deploy|
	if "#{deploy[:deploy_to]}".include? "website"
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
		
		Chef::Log.info("*********** Creating rewrite.conf  for #{deploy[:deploy_to]}...*************")
		template "/etc/apache2/sites-available/zh_website.conf.d/rewrite.conf" do
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
	
		Chef::Log.info("*********** Creating index.php  for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/current/index.php" do
			source "index.php.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:admin_url => (deploy[:admin_site] rescue nil),
				:s3_bucket => (deploy[:s3_bucket] rescue nil)
			)
		end
	
		Chef::Log.info("*********** Creating mobile index.php  for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/current/mobile/index.php" do
			source "mobile_index.php.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:admin_url => (deploy[:admin_site] rescue nil),
				:s3_bucket => (deploy[:s3_bucket] rescue nil)
			)
		end
	
		
		script "variousfiles" do
			interpreter "bash"
			user "root"
			code <<-EOH
				PROXY_HOST=#{deploy[:proxy][:host]};
				if ! grep "$PROXY_HOST" /etc/hosts ; then 
					echo `host $PROXY_HOST | cut -d' ' -f4` $PROXY_HOST >> /etc/hosts; 
				fi
			EOH
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
		
				
		Chef::Log.info("*********** Creating rewrite.conf  for #{deploy[:deploy_to]}...*************")
		template "/etc/apache2/sites-available/zh_admin.conf.d/rewrite.conf" do
			source "rewrite.conf.erb"
			mode 0660
			group deploy[:group]
			owner "root"
		end

		
	end
	
end

