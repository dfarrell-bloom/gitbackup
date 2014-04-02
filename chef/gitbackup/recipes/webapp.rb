#
# Cookbook Name:: gitbackup
# Recipe:: webapp
#
# Copyright (C) 2014 Dan Farrell
# 


bash "apt update" do 
    code "apt-get update"
end

r = package "git" do 
    action :nothing
end
r.run_action(:install);

%w{ build-essential ruby1.9.1 ruby1.9.1-dev gem }.each do |pkg|
    package pkg do
        action :install
    end
end

gem_package "bundler" do 
    action :install
end

git ::File.join( node['gitbackup']['home'], "gitbackup") do
    repository node['gitbackup']['repository']
    revision node['gitbackup']['checkout'] 
    user node['gitbackup']['user']
    action :sync
end

config_resource = file ::File.join( node['gitbackup']['home'], "gitbackup", "config.json") do
    action :nothing
end

bash "invoke bundle" do
    code "bundle install"
    cwd ::File.join( node['gitbackup']['home'], 'gitbackup' )
end

## update config.json from the repo based on chef attributes.
ruby_block "update app config" do 
    block do
        config_template = JSON.parse( ::File.read ( ::File.join node['gitbackup']['home'], "gitbackup", "config.json" ) )
        config_template.reject! { |k,v| k =~ %r{^//} }
        node['gitbackup']['webapp'].each_key do |k| 
            config_template[k] = node['gitbackup']['webapp'][k]
        end
        config_resource.content JSON.pretty_generate( config_template) 
        config_resource.run_action :create
    end
end

## Write out the upstart job
template "/etc/init/gitbackup_webapp.conf" do
   source "gitbackup_webapp.conf.erb"
end

file "/var/log/gitbackup.log" do
    owner node['gitbackup']['user']
    mode 0600
    action :create_if_missing
end

node['gitbackup']['webapp']['seed_repos'].each do |config|
    homedir =::File.join( '/', 'home', config['user'] ) 
    user config['user'] do
        action :create
        shell `which bash`.strip
        home homedir
        system true
        supports :manage_home => true
    end
    bash "update homedir permissions" do
       code "chmod 0700 #{homedir}" 
    end
	directory ::File.join(homedir, ".ssh" ) do
	    action :create
	    mode 0700
        owner config['user']
	end
    bash "scan for github ssh host cert" do
        user config['user']
        code <<-eof
        grep github.com "#{::File.join homedir, '.ssh', 'known_hosts' }" || /
        ssh-keyscan github.com >#{::File.join homedir, '.ssh', 'known_hosts' } 2>/dev/null
        eof
        umask 0177
    end
    file ::File.join( homedir, '.ssh', config['name'] ) do
        content node['gitbackup']['webapp']['private_keys'][ config['private_key'] ]
        owner config['user']
        mode 0400
    end
    auth_file_resource ||= Hash.new
    auth_file_resource[config['user']] = file ::File.join( homedir, '.ssh', 'authorized_keys' ) do
        mode 0600
        owner config['user']
        action :nothing
    end
    # execute at runtime to read the auto-generated ssh key from the gitbackup user 
    ruby_block "create authorized_keys for #{config['user']}" do
        block do   
            auth_file_resource[config['user']].content(  
                 ( [ 
                    %q{from="127.0.0.1" } + 
                    ::File.read( ::File.join node['gitbackup']['home'], '.ssh', 'id_rsa.pub' ).strip 
                ] + 
                config['public_keys'].map{ |pubkey|
                    %q{command="perl -e 'exec qw(git-shell -c), $ENV{SSH_ORIGINAL_COMMAND}'" } + 
                    node['gitbackup']['webapp']['public_keys'][ pubkey ].strip
                }
                ).join("\n") + "\n"
            )
            auth_file_resource[config['user']].run_action :create
        end
    end
end

include_recipe "gitbackup::webapp_start"

