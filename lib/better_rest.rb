#!/usr/bin/env ruby

require 'sinatra'
require 'typhoeus'

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
	@headerHash = {}
	@validHeaderCount = 1
	@formResponse = true
	@follow, @verbose, @ssl, @loggingOn = true, true, false, false
	@requestBody = ""
	@visible = [params[:serveURLDiv], params[:serveAuthDiv], params[:serveHeaderDiv], params[:servePayloadDiv], params[:serveResultsDiv]]

	(0..Integer(params[:headerCount])).each do |i|
		@keyIncrement = "key" + "#{i}"
		@valueIncrement = "value" + "#{i}"

		if params[@keyIncrement] and not params[@keyIncrement].empty? and params[@valueIncrement] and not params[@valueIncrement].empty?
			@headerHash[params[@keyIncrement]] = params[@valueIncrement]
			@validHeaderCount += 1
		end
	end

	if @headerHash["User-Agent"] == nil		#add branded User-Agent header, only if empty
		@headerHash["User-Agent"] = "BetteR - https://github.com/at1as/BetteR"
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
	if params[:enableLogging] == "on"
		@loggingOn = true
	end
	unless params[:datafile].nil?
		@requestBody = { content: params[:payload], file: File.open(params[:datafile][:tempfile], 'r') }
	else
		@requestBody = { content: params[:payload] }
	end

	request = Typhoeus::Request.new(
		params[:url],
	  	method: params[:requestType],
	  	:username => params[:usr],
		:password => params[:pwd],
		:auth_method => :auto,		#Should be manually set in order to test unideal APIs
	  	:headers => @headerHash,
	  	:body => @requestBody,		#to replace -> body: params[:payload],
	  	followlocation: @follow,
	  	verbose: @verbose,
	  	ssl_verifypeer: @ssl,
	  	:timeout => Integer(params[:timeoutInterval])
	)

	request.run
	response = request.response

	if @headerHash["User-Agent"] == "BetteR - https://github.com/at1as/BetteR"
		@headerHash.delete("User-Agent")
	end

	if @loggingOn == true
		File.open('log/' + Time.now.strftime("%Y-%m-%d") + '.log', 'a') { 
			|file| file.write("-"*10 + "\n" + Time.now.to_s + request.inspect + "\n\n" ) 
		}
	end

	puts params[:payload]

	@requestOptions = request.options
	@returnBody = response.body 
	@returnCode = response.return_code
	@returnTime = response.time
	@statCodeReturn = response.response_headers

	@requests = ["#{params[:requestType]}", "GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"].uniq
	@timeout = ["1","2","5","10","60"]
	erb :index
end