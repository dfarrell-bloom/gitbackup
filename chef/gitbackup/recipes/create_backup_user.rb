#
# Cookbook Name:: gitbackup
# Recipe:: create_backup_user
#
# Copyright (C) 2014 Dan Farrell
# 

user node['gitbackup']['user'] do
    action :create
    shell `which bash`.strip
    home node['gitbackup']['home']
    system true
    supports :manage_home => true
end

directory ::File.join(node['gitbackup']['home'], ".ssh" ) do
    action :create
    mode 0700
    owner node['gitbackup']['user']
end

bash "scan for github ssh host cert" do 
    user node['gitbackup']['user']
    code <<-eof
    for host in github.com localhost 127.0.0.1; do
    grep "$host" "#{File.join node['gitbackup']['home'], '.ssh', 'known_hosts' }" || /
      ssh-keyscan $host >>#{File.join node['gitbackup']['home'], '.ssh', 'known_hosts' } 2>/dev/null
    done
    eof
    umask 0177
end

bash "create ssh key" do 
    code %Q{ssh-keygen -P "" -f #{File.join node['gitbackup']['home'], '.ssh', 'id_rsa'} }
    user node['gitbackup']['user']
    not_if { ::File.exists? ::File.join(node['gitbackup']['home'], '.ssh', 'id_rsa') }
end
