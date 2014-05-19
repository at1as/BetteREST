#!/usr/bin/env ruby

require 'sinatra'
require 'typhoeus'

set :public_dir, File.expand_path('../../public', __FILE__)
set :views, File.expand_path('../../views', __FILE__)

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

BETTER_SIGNATURE = "BetteR - https://github.com/at1as/BetteR"

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
  @visible = [:servURLDiv, :servAuthDiv, :servHeaderDiv, :servePayloadDiv, :servResultsDiv].map{ |k| params[k] }

  # Loop through Header key/value pairs
  params[:headerCount].to_i.times do |i|
    @keyIncrement = "key#{i}"
    @valueIncrement = "value#{i}"

  # If a header is created and deleted before submit, headerCount will not renormalize (and will therefore exceed the number of sent headers)
  # This will check that a particular header exists, before adding it
    if !(params.fetch(@keyIncrement, '').empty? || params.fetch(@valueIncrement, '').empty?)
      @headerHash[params[@keyIncrement]] = params[@valueIncrement]
      @validHeaderCount += 1
    end
  end

  # Shameless branding. Only if User-Agent isn't user specified
  @headerHash["User-Agent"] ||= BETTER_SIGNATURE

  # Check which options the user set
  @follow = false if params[:followlocation] == ""

  @verbose = false if params[:verbose] == ""

  @ssl = true if params[:ssl_verifypeer] == "on"

  @loggingOn = true if params[:enableLogging] == "on"

  if params[:datafile]
    @requestBody = { content: params[:payload], file: File.open(params[:datafile][:tempfile], 'r') }
  else
    @requestBody = { content: params[:payload] }
  end

  # Create the Request
  request = Typhoeus::Request.new(
    params[:url],
    method: params[:requestType],
    username: params[:usr],
    password: params[:pwd],
    auth_method: :auto,		#Should ideally not be auto, in order to test unideal APIs
    headers: @headerHash,
    body: @requestBody,
    followlocation: @follow,
    verbose: @verbose,
    ssl_verifypeer: @ssl,
    timeout: Integer(params[:timeoutInterval])
  )

  # Send the request
  request.run
  response = request.response

  # If user-agent wasn't set by user, don't bother showing the user this default
  @headerHash.delete("User-Agent") if @headerHash["User-Agent"] == BETTER_SIGNATURE

  # Log the request response
  if @loggingOn
    File.open('log/' + Time.now.strftime("%Y-%m-%d") + '.log', 'a') do |file|
      file.write("-" * 10 + "\n" + Time.now.to_s + request.inspect + "\n\n" )
    end
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
