# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the config file wp-config.php and links things.

require 'uri'
require 'net/http'
require 'net/https'


include_recipe 'apache2::mod_proxy'
include_recipe 'apache2::mod_proxy_http'


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
				:keys       => (keys rescue nil)
			)
		end
	else
		Chef::Log.info("************* Skipping wp-config.php for #{deploy[:deploy_to]}...*************")
	end
	
	if "#{deploy[:deploy_to]}".include? "wordpress"
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

