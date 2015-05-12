file "robots.txt" do
  owner 'root'
  group 'root'
  mode '0777'
  action :create
  content "User-agent: *\nDisallow: /"
end
