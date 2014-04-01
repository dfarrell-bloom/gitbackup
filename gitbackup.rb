require 'rubygems'
require 'sinatra'
require 'json'
require 'fileutils'

set :bind, "0.0.0.0"

post "/" do
	begin
		data = JSON.parse( params[:payload] )
	rescue Exception=>e
		puts "Couldn't parse payload: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
		halt 400, "json could not be parsed: #{e.message}"
	end
    # for testing.  I need to look at this.
	File.open( '/tmp/commit.json', "w" ) do |f|
		f.write params[:payload]
	end
	repo = Repository.new data
	if repo.updateRepository
		halt 200, "Updated - thanks!"
	else
		halt 500, "Repository could not be updated - sorry!"
	end
end


class Repository 
	@@basepath = "~/gitbackup"

	def initialize data
		@data = data
	end
	
	def cloneRepository
		FileUtils.mkpath path unless Dir.exists? path
		if Dir.exists? repoPath
			Kernel.system "cd #{repoPath}; git status || return -1; git remote -v | grep '#{gitUrl}' "
			return true if $? == 0 # repo is available and remote path is in the remotes ( doesn't matter if it's the only one or not) 
		end
		Kernel.system "cd #{path}; git clone '#{gitUrl}' '#{repoPath}' "
		return $? == 0 
	end

	def fetchRepository 
		Kernel.system "cd #{repoPath}; git fetch --all"
		return $? == 0 
	end 

	def updateRepository
		return false unless cloneRepository
		return fetchRepository
	end

	def path
		return File.expand_path @@basepath
	end

	def repoPath 
		return "#{path}/#{@data['repository']['name']}"
	end

	def gitUrl 
		url = @data['repository']['url']
		return url.gsub( %r|^https://([^/]+)/|, 'git@\1:' )
	end

end
