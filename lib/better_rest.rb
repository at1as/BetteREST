#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'typhoeus'
require 'json'

set :public_dir, File.expand_path('../../public', __FILE__)
set :views, File.expand_path('../../views', __FILE__)

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

configure do
  dirs = ['logs', 'requests', 'tmp']
  dirs.each do |folder|
    Dir.mkdir(folder) unless File.directory? folder
  end
end

BETTER_SIGNATURE = "BetteR - https://github.com/at1as/BetteR"


# Return default values
get '/?' do
  @requests = ["GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"]
  @times = ["1", "2", "5", "10"]
  @validHeaderCount = 1
  @header_hash = {"" => ""}
  @follow, @verbose, @ssl, @log_requests = true, true, false, false
  @payloadHeight = "100px"
  @resultsHeight = "180px"
  @timeout_interval = 1

  erb :index
end


# Send a request
before '/request' do
  request.body.rewind
  @request_body = JSON.parse request.body.read
end

post '/request' do
  puts @request_body

  # Request Configuration
  @follow = @request_body['redirect'] rescue false
  @verbose = @request_body['verbose'] rescue false
  @ssl = @request_body['ssl_ver'] rescue false
  @log_requests = @request_body['logging'] rescue false
  @timeout_interval = Integer(@request_body['timeout']) rescue 1
  @request_body['headers']['User-Agent'] = BETTER_SIGNATURE unless @request_body['headers']['User-Agent']

  # Create the Request
  hydra = Typhoeus::Hydra.new
  request = Typhoeus::Request.new(
    @request_body["url"],
    method: @request_body["request"],
    username: @request_body["user"],
    password: @request_body["password"],
    auth_method: :auto,
    headers: @request_body["headers"],
    body: @request_body["payload"],
    followlocation: @follow,
    verbose: @verbose,
    ssl_verifypeer: @ssl,
    timeout: @timeout_interval
  )

  # Modify request object if necessary
  unless @request_body['file'].empty?
    request.options[:body] = { content: @request_body['payload'], file: File.open(@request_body['file'], 'r') }
  end

  # Remove unused fields from request
  request.options.delete(:body) if request.options[:body].empty?
  if @request_body['user'].empty? || @request_body['password'].empty?
    request.options.delete(:username)
    request.options.delete(:password)
    request.options.delete(:auth_method)
  end

  # Send the request (specified number of times)
  @request_body['quantity'].to_i.times.map{ hydra.queue(request) }
  hydra.run
  response = request.response

  # Log the request
  if @log_requests
    File.open('logs/' + Time.now.strftime('%Y-%m-%d') + '.log', 'a') do |file|
      file.write('-' * 10 + ?\n + Time.now.to_s + request.inspect + "\n\n")
    end
  end

  # View response parameters
  @response_body = {}
  request.options[:url] = request.url
  @response_body['request_options'] = JSON.pretty_generate(request.options)
  @response_body['return_msg'] = response.return_code.upcase
  @response_body['return_code'] = response.code
  @response_body['return_time'] = response.time
  @response_body['return_body'] = response.body.inspect
  @response_body['return_headers'] = response.response_headers

  @response_body.to_json
end


# Save Request
before '/save' do
  request.body.rewind
  @request_payload = JSON.parse request.body.read
end

post '/save' do
  name = @request_payload['name']
  collection = @request_payload['collection']

  if File.exists? "requests/#{collection}.json"
    stored_collection = JSON.parse File.read("requests/#{collection}.json")
  else
    stored_collection = {}
  end
  stored_collection[name] = @request_payload

  File.open("requests/#{collection}.json", "w") do |f|
    f.write(stored_collection.to_json)
  end
end


# Load List of Requests
get '/savedrequests' do
  collection_map = {}
  collections = Dir["requests/*.json"]

  collections.each do |collection|
    collection_contents = JSON.parse File.read(collection)
    collection_names = collection_contents.keys

    # Strip extension and directory from filename
    collection = collection[9..-6]
    collection_map[collection] = collection_names.sort
  end

  if collections.length > 0
    return collection_map.to_json
  else
    return 404
  end
end


# Load Request
get '/savedrequests/:collection/:request' do
  if File.exists? "requests/#{params[:collection]}.json"
    collection = JSON.parse File.read("requests/#{params[:collection]}.json")
    request = collection[params[:request]]
    return request.to_json
  else
    return 404
  end
end


# Delete Request Collection
delete '/collections/:collection' do
  if File.exists? "requests/#{params[:collection]}.json"
    File.delete("requests/#{params[:collection]}.json")
  else
    return 404
  end
end


# Delete Request from Collection
delete '/collections/:collection/:request' do
  if File.exists? "requests/#{params[:collection]}.json"
    stored_collection = JSON.parse File.read("requests/#{params[:collection]}.json")
    stored_collection.delete(params[:request])

    File.open("requests/#{params[:collection]}.json", "w") do |f|
      f.write(stored_collection.to_json)
    end
  else
    return 404
  end
end


# Retrieve list of saved logs
get '/logs' do
  entries = Dir["logs/*.log"]
  return entries.map{ |k| k[5..-5]}
end


# Download log
get '/logs/:log' do
  begin
    send_file "logs/#{params[:log]}.log"
  rescue
    return 404
  end
end


# Upload file
# TODO: Maximum file size, cleanup tmp directory, etc
post '/upload' do
  unless params['datafile'].nil?
    File.open('tmp/' + params['datafile'][:filename], 'w') do |f|
      f.write(params['datafile'][:tempfile].read)
    end
  end
end


# Defaults to main page
not_found do
  redirect '/'
end


# Returns Ruby/Sinatra Environment details
get '/env' do
  <<-ENDRESPONSE
      Ruby:    #{RUBY_VERSION} <br/>
      Rack:    #{Rack::VERSION} <br/>
      Sinatra: #{Sinatra::VERSION}
  ENDRESPONSE
end


# Kills process. Work around for Vegas Gem not catching SIGINT from Terminal
get '/quit' do
  redirect to('/'), 200
end

after '/quit' do
  puts  "\nExiting..."
  exit!
end
