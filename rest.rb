#!/usr/bin/env ruby

require 'sinatra'
require 'json'
require 'typhoeus'

helpers do
	include Rack::Utils
	alias_method :h, :escape_html
end

get '/?' do
	@requests = ["GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"]
	@timeout = ["1","2","3","4","5","10"]
	@validHeaderCount = 1
	@headerHash = {"" => ""}
	@follow, @verbose, @ssl = true, true, false
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
	@headerHash = {}
	@validHeaderCount = 1
	@formResponse = true
	@follow, @verbose, @ssl = true, true, false
		

	(0..Integer(params[:headerCount])).each do |i|
		@keyIncrement = "key" + "#{i}"
		@valueIncrement = "value" + "#{i}"

		if params[@keyIncrement] and not params[@keyIncrement].empty? and params[@valueIncrement] and not params[@valueIncrement].empty?
			@headerHash[params[@keyIncrement]] = params[@valueIncrement]
			@validHeaderCount += 1
		end
	end

	if params[:followlocation] == ""
		@follow = false
	end
	if params[:verbose] == ""
		@verbose = false
	end
	if params[:ssl_verifypeer] == "on"
		@ssl = true
	end

	request = Typhoeus::Request.new(
		params[:url],
	  	method: params[:requestType],
	  	:username => params[:usr],
		:password => params[:pwd],
		:auth_method => :auto,		#Should be manually set in order to test unideal APIs
	  	body: params[:payload],
	  	:headers => @headerHash,
	  	#Constants. These should be made configurable
	  	followlocation: @follow,
	  	verbose: @verbose,
	  	ssl_verifypeer: @ssl,
	  	:timeout => Integer(params[:timeoutInterval])
	)

	request.run
	response = request.response
	puts request.inspect 	#for debug only

	puts "!!!!"
	puts !!@ssl = @ssl
	puts !!@follow = @follow
	puts !!@verbose = @verbose

	@requestOptions = request.options.to_json
	@returnBody = response.body 
	@returnCode = response.return_code
	@returnTime = response.time
	@statCodeReturn = response.response_headers

	@requests = ["#{params[:requestType]}", "GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"].uniq
	@timeout = ["1","2","3","4","5","10"].uniq
	erb :index
end

