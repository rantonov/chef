# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the Zendyhealth API config files


# Create the config.properties 
node[:deploy].each do |app_name, deploy|

	if "#{deploy[:deploy_to]}".include? "zendyhealthapi"
		
		%w[ #{deploy[:deploy_to]}/ops #{deploy[:deploy_to]}/ops/zendyhealthapi #{deploy[:deploy_to]}/ops/zendyhealthapi/conf ].each do |path|
			directory path do
				owner 'apache'
				group 'deploy'
				mode '0777'
				action 'create'
			end
		end

		Chef::Log.info("*********** Creating API properties for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/ops/zendyhealthapi/conf/config.properties" do
			source "config.properties.erb"
			mode 0660
			group deploy[:group]
			owner "apache"

			variables(
				:db_url			=> (deploy[:database][:username] rescue nil),
				:db_dbname		=> (deploy[:database][:database] rescue nil),
				:db_username   	=> (deploy[:database][:password] rescue nil),
				:db_password    => (deploy[:database][:host] rescue nil),

				:site_url		=> (deploy[:site_urls][:this] rescue nil),
				:admin_site_url => (deploy[:site_urls][:admin] rescue nil),

				:stripe_key     => (deploy[:externals][:stripe] rescue nil),
				:paypal_config_file  => (deploy[:externals][:paypal] rescue nil),

				:s3_bucket    	=> (deploy[:s3][:bucket] rescue nil),
				:s3_key       	=> (deploy[:s3][:key] rescue nil),
				:s3_secret   	=> (deploy[:s3][:secret] rescue nil),

				:jotform_key  	=> (deploy[:externals][:jotform] rescue nil)
			)
		end


		Chef::Log.info("*********** Creating Logback configuration for #{deploy[:deploy_to]}...*************")
		template "#{deploy[:deploy_to]}/ops/zendyhealthapi/conf/logback.xml" do
			source "logback.xml.erb.erb"
			mode 0660
			group deploy[:group]
			owner "apache"

			variables(
				:log_absolute_path	=> (deploy[:logback][:absolute_path] rescue nil),
				:app_name			=> (deploy[:logback][:app_name] rescue nil),
				:max_history   		=> (deploy[:logback][:max_history] rescue nil),
				:log_level    		=> (deploy[:logback][:log_level] rescue nil)
			)
		end
		
		link "#{deploy[:deploy_to]}/ops" do
			to "/usr/share/tomcat7/"
			mode "0777"
			owner "root"
		end
		
	end
end

