script "configurewebsites" do
		interpreter "bash"
		user "root"
		code <<-EOH
				sed -i "/HessianServiceUrl/c\    define('HessianServiceUrl', 'http://internal-dev-api-lb-75921361.us-west-2.elb.amazonaws.com:8080/zendyhealthapi/services');" /srv/www/zh_website/current/application/config/application.config.php ;
				sed -i "/HessianServiceUrl/c\\$this->AddRow('HessianServiceUrl', 'http://internal-dev-api-lb-75921361.us-west-2.elb.amazonaws.com:8080/zendyhealthapi/services');" /srv/www/zh_admin/current/app/data/setting.db.php ;
		EOH
end
