require_relative 'ssh.rb'

class Repository 
	
    attr_reader :results

	class RepositoryException < Exception
	end

	class UnconfiguredException < Exception
	end

	def initialize data
		@data = data
		@configs = seed_repo_configs
		raise UnconfiguredException.new "No backup configured for #{name}" unless @configs.count > 0
        @results = []
	end
	
	def cloneRepository
		user_results = @configs.map { |config|
			##$stderr.puts "Checking on repo #{config['name']} under #{config['user']}"
			Net::SSH.start( 'localhost', config['user'] ) { |ssh|
        		res = ssh.exec_st "cd #{Shellwords.shellescape config['name']} || exit 127 ; git remote -v | grep '#{Shellwords.shellescape config['url']}'" 
				if res[:status] != 0 
					##$stderr.puts "Checked on repo under #{config['user']}: got #{res.inspect}"
					res = ssh.exec_st gitcommand( config, [ 'clone', '--mirror', config['url'], config['name']  ] )
				end
				res
			}
		}
		# $stderr.puts "Results from all users: #{user_results.inspect}"
        @results << { cloneRepository: user_results } 
		return ( user_results ).select{ |res| res[:status] != 0 }.count  == 0 
	end

	def fetchRepository 
        res = sysgit( "fetch", "--all" )
		# $stderr.puts "Results for fetchRepository: #{res.inspect}"
        @results << {fetchRepository: res }
		return res.select{ |res| res[:status] != 0 }.count  == 0
	end 

	def updateRepository
		unless cloneRepository
			$stderr.puts "Repository not cloned, cannot fetch."
			return false 
		else
			return fetchRepository
		end
	end

	def name
		@data['repository']['name']
	end

	def url
		@data['repository']['url']
	end 
	
	def repoPath 
		File.join '~', name
	end

	def gitUrl 
		url.gsub( %r|^https://([^/]+)/|, 'git@\1:' )
	end
	
	def gitLog 
		return sysgit "log", "-n", "1" 
	end
	
	def seed_repo_configs
		return $config['seed_repos'].select do |sr|
			#$stderr.puts "Config matches #{name}: #{sr.to_json}"
			sr['name'] == name 
		end
	end

	## unified interface for other user / basepath sysgit 
	def sysgit *args
		raise UnconfiguredException.new "Repository not configured: #{name}" unless @configs.count > 0 # defined in config
		@configs.map do |config|
			sysgit_ssh config, args
		end
	end

	## for sysgit as another user ( per config )
	def sysgit_ssh config, args
		# $stderr.puts "Executing git for repo #{config['name']} under #{config['user']}"
		Net::SSH.start( 'localhost', config['user'] ) do |ssh|
        	ssh.exec_st(gitcommand config, args)
		end
	end

	def gitcommand config, args
		# $stderr.puts "gitcommand: #{config.inspect}, args #{args.inspect}"
	 	cmd = args.clone.unshift( 'git' ).map{ |arg| Shellwords.shellescape(arg) } 
		if config['private_key'] 
			cmd = %W|cd $HOME/#{config['name'] }; ssh-agent bash -c "ssh-add #{
						File.join "~", ".ssh", Shellwords.escape( config['private_key'] )
					} && #{Shellwords.shelljoin cmd}"|.join " "
		end
		cmd
	end

end
