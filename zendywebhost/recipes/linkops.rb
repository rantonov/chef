script "linkops" do
		interpreter "bash"
		user "root"
		code <<-EOH
			    rm -rf /usr/share/tomcat7/ops;
				ln -s /usr/share/tomcat7/webapps/zendyhealthapi/ops /usr/share/tomcat7/;
				service tomcat7 restart;
		EOH
end
