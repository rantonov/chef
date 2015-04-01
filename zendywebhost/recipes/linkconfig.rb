# the Environment variable is one of {dev|test|prod}

script "linkconfigs" do
		interpreter "bash"
		user "root"
		cwd "#{deploy[:deploy_to]}/current/"
		code <<-EOH
			ln -s #{deploy[:deploy_to]}/current/wp-configs/wp-config_zh_${Environment}.php #{deploy[:deploy_to]}/current/wp-config.php;
			ln -s #{deploy[:deploy_to]}/shared/content #{deploy[:deploy_to]}/current/wp-content;
		EOH
end
