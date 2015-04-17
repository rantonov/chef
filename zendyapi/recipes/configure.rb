# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the Zendyhealth API config files



# Create the config.properties 
node[:deploy].each do |app_name, deploy|
	
	if "#{deploy[:deploy_to]}".include? "zendyhealthapi"
	
		#Create the ops directory structure
		directory "/usr/share/tomcat7/ops" do
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		directory "/usr/share/tomcat7/ops/zendyhealthapi" do
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		directory "/usr/share/tomcat7/ops/zendyhealthapi/conf" do
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		directory "/usr/share/tomcat7/ops/zendyhealthapi/keystore" do
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end

		#copy files
		cookbook_file  "/usr/share/tomcat7/ops/zendyhealthapi/keystore/keystore.jks" do
		  source "keystore.jks"
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		cookbook_file  "/usr/share/tomcat7/ops/zendyhealthapi/conf/ehcache.xml" do
		  source "ehcache.xml"
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		cookbook_file  "/usr/share/tomcat7/ops/zendyhealthapi/conf/vcache.vcl" do
		  source "vcache.vcl"
		  owner 'root'
		  group 'tomcat'
		  mode '0777'
		end
		

		Chef::Log.info("*********** Creating API properties *************")
		template "/usr/share/tomcat7/ops/zendyhealthapi/conf/config.properties" do
			source "config.properties.erb"
			mode 0777
			group deploy[:group]
			owner "apache"

			variables(
				:db_url			=> (deploy[:database][:host] rescue nil),
				:db_dbname		=> (deploy[:database][:database] rescue nil),
				:db_username   	=> (deploy[:database][:username] rescue nil),
				:db_password    => (deploy[:database][:password] rescue nil),

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


		Chef::Log.info("*********** Creating Logback configuration  *************")
		template "/usr/share/tomcat7/ops/zendyhealthapi/conf/logback.xml" do
			source "logback.xml.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:log_absolute_path	=> (deploy[:logback][:absolute_path] rescue nil),
				:app_name			=> (deploy[:logback][:app_name] rescue nil),
				:max_history   		=> (deploy[:logback][:max_history] rescue nil),
				:log_level    		=> (deploy[:logback][:log_level] rescue nil)
			)
		end

		Chef::Log.info("*********** Creating Logback configuration  *************")
		template "/usr/share/tomcat7/ops/zendyhealthapi/conf/paypal_config.properties" do
			source "paypal_config.properties.erb"
			mode 0777
			group deploy[:group]
			owner "root"

			variables(
				:client_id		=> (deploy[:paypal][:client_id] rescue nil),
				:client_secret  => (deploy[:paypal][:client_secret] rescue nil),
				:endpoint		=> (deploy[:paypal][:endpoint] rescue nil)
			)
		end

		
		bash '(re-)start autofs earlier' do
		  user 'root'
		  code <<-EOC
			service tomcat7 restart
		  EOC
		  notifies :restart, resources(:service => 'tomcat')
		end

	end
end

