#
# Cookbook Name:: gitbackup
# Recipe:: default
#
# Copyright (C) 2014 Dan Farrell
# 

include_recipe "gitbackup::create_backup_user"
include_recipe "gitbackup::webapp"
