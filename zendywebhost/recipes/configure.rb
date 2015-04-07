# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the config file wp-config.php with MySQL data.
# - Imports a database backup if a *.sql file exists in the current htdocs directory exists.

require 'uri'
require 'net/http'
require 'net/https'

uri = URI.parse("https://api.wordpress.org/secret-key/1.1/salt/")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
keys = response.body

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


# Create the Wordpress config file wp-config.php with corresponding values
node[:deploy].each do |app_name, deploy|
	if "#{deploy[:deploy_to]}".include? "wordpress"
		Chef::Log.info("Creating wp-config.php for #{deploy[:deploy_to]}...")
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
				:keys       => (keys rescue nil)
			)
		end
	else
		Chef::Log.debug("Skipping wp-config.php for #{deploy[:deploy_to]}...")
	end
	script "linkconfigs" do
		interpreter "bash"
		user "root"
		code <<-EOH
			rm -rf #{deploy[:deploy_to]}/current/wp-content;
			ln -s /srv/www/zh_wordpress/shared/content #{deploy[:deploy_to]}/current/wp-content;
		EOH
	end
end


	# Import Wordpress database backup from file if it exists
	mysql_command = "/usr/bin/mysql -h #{deploy[:database][:host]} -u #{deploy[:database][:username]} #{node[:mysql][:server_root_password].blank? ? '' : "-p#{node[:mysql][:server_root_password]}"} #{deploy[:database][:database]}"

	Chef::Log.debug("Importing Wordpress database backup...")
	script "memory_swap" do
		interpreter "bash"
		user "root"
		cwd "#{deploy[:deploy_to]}/current/"
		code <<-EOH
			if ls #{deploy[:deploy_to]}/current/*.sql &> /dev/null; then 
				#{mysql_command} < #{deploy[:deploy_to]}/current/*.sql;
				rm #{deploy[:deploy_to]}/current/*.sql;
			fi;
		EOH
	end
	