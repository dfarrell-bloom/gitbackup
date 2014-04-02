require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe "Chheck that user and homedir and .ssh are created, and github host cert is installed" do
    describe user("gitbackuper") do
        it { should exist }
    end
    describe file( "/home/gitbackuper" ) do
        it { should be_directory }
        it { should be_owned_by 'gitbackuper' }
    end
    describe file("/home/gitbackuper/.ssh") do
        it { should be_directory }
        it { should be_owned_by 'gitbackuper' }
        it { should be_mode 700 }
    end
    describe file("/home/gitbackuper/.ssh/known_hosts") do
        it { should be_owned_by 'gitbackuper' }
        it { should be_mode 600 }
    end
    describe command("grep github.com /home/gitbackuper/.ssh/known_hosts") do 
        it { should return_exit_status 0 }
    end
    describe command("grep 127\\.0\\.0\\.1 /home/gitbackuper/.ssh/known_hosts") do 
        it { should return_exit_status 0 }
    end
end

describe "Check that git is installed" do 
    describe command("which git") do 
        it {should return_exit_status 0 } 
    end
end

describe "Check that repository is checked out" do 
    describe file( "/home/gitbackuper/gitbackup" ) do 
        it { should be_directory }
        it { should be_owned_by "gitbackuper" }
    end
    describe file( "/home/gitbackuper/gitbackup/.git" ) do 
        it { should be_directory }
    end
    describe command("cd /home/gitbackuper/gitbackup/ && git status" ) do
        it { should return_exit_status 0 }
    end
end

describe "Check config file got the correct values" do
    describe file("/home/gitbackuper/gitbackup/config.json") do
        it { should be_file }
        its(:content) { should =~ %r{"token":\s*"TestToken"} }
        its(:content) { should =~ %r{"name":\s*"backuptesting"}}
        its(:content) { should =~ %r{"url":\s*"git@github\.com:bloomhealth/backuptesting\.git"} }
    end
end

describe "Check that upstart script is created and started" do 
    describe file("/etc/init/gitbackup_webapp.conf") do
        it { should be_file }
    end
    describe service("gitbackup_webapp") do
        it { should be_enabled }
        it { should be_running }
    end
end

describe "Check that the backup users got an ssh key" do 
    describe file("/home/gitbackuper/.ssh/id_rsa") do
        it { should be_file }
    end
    describe file("/home/gitbackuper/.ssh/id_rsa.pub") do
        it { should be_file }
    end
end

backuper_content= %Q{from="127.0.0.1" #{::File.read('/home/gitbackuper/.ssh/id_rsa.pub').strip}}
pubkey1 = %Q{command="perl -e 'exec qw\(git-shell -c\), \$ENV{SSH_ORIGINAL_COMMAND}'" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLiXgnpat5q6gnFkrGiZTbf/nKNhCpYQfghlSSPiBopunC/pOwYxVm2m3XV6/61VoQiO3LqThH5Gmdnog0Ak9pxMBm8rdd3XwedfzDjYDFx8WJ/CeuMaNLvIMjCWS2/wM6O2tRkegTwbT6pIL4bwEIlqgWmOHU1bo2Rw1Hwv6WstoJq+85XZ8dbFWXQEqEJq0+NvHPJwS/U0D7u++r/a6/2kjideDq8OPu0lEIisfGqPx65lpZvjQPxpHYo1WSc3yU85I9hiC3kit5PLbX0Q3Bi5TwVAbXkMJYQhG3ovKMvZlVov/fPCvMSoVRp3Qbx1DTPmJPMAY2BzOYbzNhjC6N backuptesting-pull}
pubkey2 = %Q{command="perl -e 'exec qw\(git-shell -c\), \$ENV{SSH_ORIGINAL_COMMAND}'" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDC4JoS85zuWmMLtRrOIXQmd1SJ6wj2RGYDii91fMZUr5UKa42AvG/E6M38RamxgN+0Tq0ScFSkn5aRE4T/F5DMvT4IzDRkY2e+QlP8j7/ooe5BtTkZkYfhQ+Xj44eQRvQufCnSAE9Pd594ZfBfABdkyt5tdtMTt18wBxmtlhlXpQokBJBp4ZncYFcNPxhJEYok6L9rMpR87ePjnKAD17fZceD/BtyDbs/e5Dh0oncVnQ17XQ3nWqTB648TjkCo46+UHXwE7Wg0eMEsl+TL2KwT9JrSw7EkutejJ38a3QsS4kmyonR4xuGXre1UyqOUtuulAWBCgrkNnCLBnqRSqxBV backuptesting-pull-2}
describe "backuptesting user should be created properly" do 
    describe user("backuptesting") do
        it { should exist }
        it { should have_home_directory "/home/backuptesting" }
    end
    describe file("/home/backuptesting") do
        it { should be_directory }
        it { should be_mode 700 }
        it { should be_owned_by "backuptesting" }
    end
    describe file("/home/backuptesting/.ssh") do
        it { should be_directory }
        it { should be_owned_by 'backuptesting' }
        it { should be_mode 700 }
    end
    describe file("/home/backuptesting/.ssh/known_hosts") do
        it { should be_owned_by 'backuptesting' }
        it { should be_mode 600 }
    end
    describe command("grep github.com /home/backuptesting/.ssh/known_hosts") do 
        it { should return_exit_status 0 }
    end
    describe file("/home/backuptesting/.ssh/authorized_keys") do
        it { should be_file }
        it { should be_owned_by 'backuptesting' }
        it { should be_mode 600 }
        its(:content) { should == "#{backuper_content}\n#{pubkey1}\n#{pubkey2}\n" }
    end
end
 
describe "gitbackup user should be created properly" do 
    describe user("gitbackup") do
        it { should exist }
        it { should have_home_directory "/home/gitbackup" }
    end
    describe file("/home/gitbackup") do
        it { should be_directory }
        it { should be_mode 700 }
        it { should be_owned_by "gitbackup" }
    end
    describe file("/home/gitbackup/.ssh") do
        it { should be_directory }
        it { should be_owned_by 'gitbackup' }
        it { should be_mode 700 }
    end
    describe file("/home/gitbackup/.ssh/known_hosts") do
        it { should be_owned_by 'gitbackup' }
        it { should be_mode 600 }
    end
    describe command("grep github.com /home/gitbackup/.ssh/known_hosts") do 
        it { should return_exit_status 0 }
    end
    describe file("/home/gitbackup/.ssh/authorized_keys") do
        it { should be_file }
        it { should be_owned_by 'gitbackup' }
        it { should be_mode 600 }
        its(:content) { should == "#{backuper_content}\n#{pubkey2}\n" }
    end
end

system( 'apt-get install -y curl' )

describe "Webapp should be functioning ( psh-93 )" do
    describe port(4567) do
        it { should be_listening.with('tcp') }
    end
    describe command("curl -I 'http://localhost:4567/repos?token=wrong&'") do  
        its(:stdout) { should match %r|HTTP/1.1 401 Unauthorized| }
    end
    describe command("curl 'http://localhost:4567/repos?token=TestToken&'") do  
        its(:stdout) { should match %r|<a href="/repostatus/backuptesting">backuptesting</a> backuptesting@localhost:backuptesting| }
        its(:stdout) { should match %r|<a href="/repostatus/gitbackup">gitbackup</a> gitbackup@localhost:gitbackup| }
    end
    describe command("curl 'http://localhost:4567/repostatus/backuptesting?token=TestToken&'") do
        its(:stdout) { should match %r|commit [0-9a-z]{40}| } 
    end
    describe command("curl 'http://localhost:4567/repostatus/gitbackup?token=TestToken&'") do
        its(:stdout) { should match %r|commit [0-9a-z]{40}| } 
    end
    describe command(%q|curl -s -o /dev/null --write-out "%{http_code}"  -X POST -d '{"repository": {"name": "gitbackup", "url": "git@github.com:dfarrell-bloom/gitbackup.git" } }' 'http://localhost:4567/githubpush?token=TestToken'| ) do
        its(:stdout) { should match /^200$/ }
    end
    describe command(%q|curl -s -o /dev/null --write-out "%{http_code}"  -X POST -d '{"repository": {"name": "backuptesting", "url": "git@github.com:bloomhealth/backuptesting.git" } }' 'http://localhost:4567/githubpush?token=TestToken'| ) do
        its(:stdout) { should match /^200$/ }
    end
end

describe "Repos should be available for checkout with the specified key ( known to match the given public )" do
    describe command( %q|ssh-agent bash -c "ssh-add /home/gitbackup/.ssh/gitbackup; git clone gitbackup@localhost:gitbackup && rm -rf gitbackup"| ) do
        it { should return_exit_status 0 }
    end
    describe command( %q|ssh-agent bash -c "ssh-add /home/gitbackup/.ssh/gitbackup; git clone backuptesting@localhost:backuptesting && rm -rf backuptesting"| ) do
        it { should return_exit_status 0 }
    end
end


