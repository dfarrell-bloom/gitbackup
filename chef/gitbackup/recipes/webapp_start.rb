#
# Cookbook Name:: gitbackup
# Recipe:: webapp_start
#
# Copyright (C) 2014 Dan Farrell
# 

service_resource = service "gitbackup_webapp" do
    provider Chef::Provider::Service::Upstart
    action :stop
end
service_resource = service "gitbackup_webapp" do
    provider Chef::Provider::Service::Upstart
    action :start
end

