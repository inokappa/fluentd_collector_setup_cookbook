#
# Cookbook Name:: fluentd_forwarder_setup
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

bash "setup_10gen_repos" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
  echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
  EOH
  notifies :run, "execute[apt-get_update]", :immediately
end

package "mongodb-10gen" do
  action :install
end

execute "apt-get_update" do
  command "apt-get update"
end

package "snmpd" do
  action :install
end

service "snmpd" do
  supports :restart => true
end

template "/etc/snmp/snmpd.conf" do
  source "snmpd.conf.erb"
  owner "root"
  group "root"
  mode "00644"
  notifies :restart, "service[snmpd]"
end

%w{libxslt1.1 libyaml-0-2}.each do |pkgs|
  package pkgs do
    action :install
  end
end

execute "install_openssl" do
  command "dpkg -i /tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
  action :nothing
end

case node[:platform_version]
when "7.1","7.2"
  remote_file "/tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb" do
    source "http://ftp.us.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb"
    notifies :run, "execute[install_openssl]", :immediately
    not_if {File.exists?("/usr/lib/libssl.so.0.9.8")}
  end
end

execute "install_td-agent" do
  command "dpkg -i /tmp/td-agent_1.1.17-1_amd64.deb"
  action :nothing
end

remote_file "/tmp/td-agent_1.1.17-1_amd64.deb" do
  source "http://packages.treasure-data.com/debian/pool/contrib/t/td-agent/td-agent_1.1.17-1_amd64.deb"
  notifies :run, "execute[install_td-agent]", :immediately
  not_if {File.exists?("/etc/init.d/td-agent")}
end

service "td-agent" do
  supports :restart => true
end

template "/etc/td-agent/td-agent.conf" do
  source "td-agent.conf.erb"
  owner "root"
  group "root"
  mode "00644"
  notifies :restart, "service[td-agent]"
end

gem_package "fluent-plugin-mongo" do
  gem_binary("/usr/lib/fluent/ruby/bin/gem")
  action :install
  only_if {File.exists?("/usr/lib/fluent/ruby/bin/gem")}
end
