script "mountcontent" do
		interpreter "bash"
		user "root"
		code <<-EOH
				yum -y install nfs-utils;
				mkdir -p #{deploy[:deploy_to]}/shared/content;
				mount -t nfs 10.0.1.16:/usr/share/nas/wp-content  #{deploy[:deploy_to]}/shared/content
		EOH
end
