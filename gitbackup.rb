require 'json'
require_relative 'lib/repository.rb'

# read config
begin
	$config = JSON.parse( File.read "config.json" )
rescue JSON::ParserError=>e
	$stderr.puts "Fatal error: couldn't read JSON file `config.json`.  Please fix the JSON format and reload."
	exit 255
end

$config["rundir"] = Dir.pwd

require 'sinatra'
require 'fileutils'
require 'open3'
require 'shellwords' 
require 'uri'

## configure all seed repos.

$config['seed_repos'].each do |config|
	repo = Repository.new "repository"=>{ "name"=> config['name'], "url" => config['url'] }
	res = repo.updateRepository 
	unless res
		raise Exception.new "Coudln't fetch seed repository #{config.inspect}\nGot:#{res}"
	end
end

use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 300,
                           :secret => '+rVQrxX3qd5Yo5CTaNIS2QsZ8asVsMnm6mwccB8LaMc3bPSoOf1jFQ=='

set :bind, "0.0.0.0"

before "/*" do
	halt 401 unless params[:token] == $config["token"] or session[:token] == $config["token"] 
    session[:token] = params[:token] unless session[:token]
end

after "/*" do
    # this ensures we are always in the directory
    # we started in, so repo locations can be relative 
    # and will continue to work.
    Dir.chdir $config['rundir'] 
end

get "/repostatus/:reponame" do
	data = { "repository"=> { "name"=> params[:reponame] }  }
	repo = Repository.new data
	results = repo.gitLog
	$stderr.puts results.inspect
	results.map{ |res| 
		out = "<pre>#{res[:stdout]}</pre>" 
		if res[:status] != 0
			out += "<p><em>Error:</em></p><pre>#{res[:stderr]}</pre>"
		end
		"<div><h3>#{repo.name}</h3>#{out}</div>"
	}.join "\n"
end

get "/repos" do
    # list repos
    $stderr.puts Dir.entries( "." ).inspect
    result = "<h2>Backup Repositories</h2>" << 
	"<ul>" << 
	$config['seed_repos'].map { |config|
       %Q{<li><a href="/repostatus/#{URI.escape config['name'] }">#{config['name']}</a> #{config['user']}@#{request.host}:#{config['name']}</li>}
	}.join("\n") << "</ul>"
    $stderr.puts result 
    result
end

post "/githubpush" do
	rawdata = request.env["rack.input"].read
	begin
		data = JSON.parse( rawdata )
	rescue Exception=>e
		puts "Couldn't parse payload: #{e.message}\n\t#{e.backtrace.join("\n\t")}"
		halt 400, "json could not be parsed: #{e.message}"
	end
	repo = Repository.new data
	if repo.updateRepository
        content_type "text/plain"
        status 200
		"Updated - thanks!\nResults: #{repo.results.inspect}"
	else
		halt 500, "Repository could not be updated - sorry!"
	end
end


