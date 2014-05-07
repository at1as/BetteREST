#!/usr/bin/env ruby

require 'sinatra'
require 'typhoeus'

set :public_dir, File.expand_path('../../public', __FILE__)
set :views, File.expand_path('../../views', __FILE__)

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

get '/?' do
	@requests = ["GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"]
	@timeout = ["1","2","5","10","60"]
	@validHeaderCount = 1
	@headerHash = {"" => ""}
	@follow, @verbose, @ssl, @loggingOn = true, true, false, false
	@visible = ["displayed", "hidden", "displayed", "displayed", "displayed"]	#Ordered display toggle for frontend: REQUEST, AUTH, HEADERS, PAYLOAD, RESULTS
	erb :index
end

get '/env' do
	<<-ENDRESPONSE
    	Ruby:    #{RUBY_VERSION} <br/>
    	Rack:    #{Rack::VERSION} <br/>
    	Sinatra: #{Sinatra::VERSION}
  	ENDRESPONSE
end

post '/' do
	# Initalize
	@headerHash = {}
	@validHeaderCount = 1
	@formResponse = true
	@follow, @verbose, @ssl, @loggingOn = true, true, false, false
	@requestBody = ""
	@visible = [params[:serveURLDiv], params[:serveAuthDiv], params[:serveHeaderDiv], params[:servePayloadDiv], params[:serveResultsDiv]]

	# Loop through Header key/value pairs
	(0..Integer(params[:headerCount])).each do |i|
		@keyIncrement = "key" + "#{i}"
		@valueIncrement = "value" + "#{i}"

		# If a header is created and deleted before submit, headerCount will not renormalize (and will therefore exceed the number of sent headers)
		# This will check that a particular header exists, before adding it
		if params[@keyIncrement] && !params[@keyIncrement].empty? && params[@valueIncrement] && !params[@valueIncrement].empty?
			@headerHash[params[@keyIncrement]] = params[@valueIncrement]
			@validHeaderCount += 1
		end
	end

	# Shameless branding. Only if User-Agent isn't user specified
	if @headerHash["User-Agent"] == nil
		@headerHash["User-Agent"] = "BetteR - https://github.com/at1as/BetteR"
	end

	# Check which options the user set
	if params[:followlocation] == ""
		@follow = false
	end
	if params[:verbose] == ""
		@verbose = false
	end
	if params[:ssl_verifypeer] == "on"
		@ssl = true
	end
	if params[:enableLogging] == "on"
		@loggingOn = true
	end
	if !params[:datafile].nil?
		@requestBody = { content: params[:payload], file: File.open(params[:datafile][:tempfile], 'r') }
	else
		@requestBody = { content: params[:payload] }
	end

	# Create the Request
	request = Typhoeus::Request.new(
		params[:url],
	  	method: params[:requestType],
	  	:username => params[:usr],
		:password => params[:pwd],
		:auth_method => :auto,		#Should ideally not be auto, in order to test unideal APIs
	  	:headers => @headerHash,
	  	:body => @requestBody,
	  	followlocation: @follow,
	  	verbose: @verbose,
	  	ssl_verifypeer: @ssl,
	  	:timeout => Integer(params[:timeoutInterval])
	)

	# Send the request
	request.run
	response = request.response

	# If user-agent wasn't set by user, don't bother showing the user this default
	if @headerHash["User-Agent"] == "BetteR - https://github.com/at1as/BetteR"
		@headerHash.delete("User-Agent")
	end

	# Log the request response
	if @loggingOn == true
		File.open('log/' + Time.now.strftime("%Y-%m-%d") + '.log', 'a') { 
			|file| file.write("-"*10 + "\n" + Time.now.to_s + request.inspect + "\n\n" ) 
		}
	end

	# For Debug, prints to terminal. This can be supressed.
	puts params[:payload]

	# These values will be used by the ERB page
	@requestOptions = request.options
	@returnBody = response.body 
	@returnCode = response.return_code
	@returnTime = response.time
	@statCodeReturn = response.response_headers
	@requests = ["#{params[:requestType]}", "GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"].uniq
	@timeout = ["1","2","5","10","60"]

	erb :index
end

not_found do
	redirect '/'
end
