
default['gitbackup']['user'] = 'gitbackuper'
default['gitbackup']['home'] = "/home/#{node['gitbackup']['user']}"
default['gitbackup']['repository'] = "https://github.com/bloomhealth/gitbackup.git"
default['gitbackup']['checkout'] = "release"

default['gitbackup']['webapp']['token'] = "f65cebf2a000b6806e212acb2102ea35ca46a0d52a015866bc242a73feca11ab"
default['gitbackup']['webapp']['private_keys'] = { }
default['gitbackup']['webapp']['public_keys'] = { }
default['gitbackup']['webapp']['seed_repos'] = [ ]

