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

  def parse_cookies(cookies)
    cookie_hash = {}
    begin
      cookies.each do |c|
        key, value = c.split('; ').first.split('=', 2)
        cookie_hash[key] = value
      end
    rescue
      key, value = cookies.split('; ').first.split('=', 2)
      cookie_hash[key] = value
    end
    cookie_hash.to_json
  end

  def stringify_cookies(cookies)
    JSON.parse(cookies).map { |key, value| "#{key}=#{value}" }.join('; ')
  end

  def parse_postman_headers(headers)
    header_hash = {}
    header_list = headers.strip.split(': ')
    keys = header_list.select.each_with_index { |str, i| i.even? }
    values = header_list.select.each_with_index { |str, i| i.odd? }

    keys.each_with_index do |key, index|
      header_hash[key] = values[index]
    end
    header_hash
  end

end

configure do
  dirs = ['logs', 'requests', 'tmp']
  dirs.each do |folder|
    Dir.mkdir(folder) unless File.directory? folder
  end
end

BETTER_SIGNATURE = "BetteR - https://github.com/at1as/BetteR"
API_VERSION = 1.0


# Return default values
get '/?' do
  @requests = ["GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"]
  @times = ["1", "2", "5", "10"]
  @header_hash = {"" => ""}
  @follow, @cookies, @verbose = [true] * 3
  @ssl, @log_requests = [false] * 2
  @timeout_interval = 2

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
  @cookies = @request_body['cookies'] rescue true
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
    request.options[:body] = { file: File.open('tmp/' + @request_body['file'], 'r') }
  end

  # Attach cookie to header
  if @cookies && @request_body['headers']['Cookie'].nil?
    if File.exists? "cookiejar"
      cookie = File.read("cookiejar")
    end
    request.options[:headers]['Cookie'] = stringify_cookies(cookie) unless cookie.empty?
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

  # Write cookie to file
  if @cookies && response.headers_hash['set-cookie']
    cookies = parse_cookies(response.headers_hash['set-cookie'])
    File.open('cookiejar', 'w') { |file| file.write(cookies) }
  end

  # Response parameters return to View
  @response_body = {}
  request.options[:url] = request.url
  @response_body['request_options'] = JSON.pretty_generate(request.options)

  # Return message OK can be confused with 200 OK
  @response_body['return_msg'] = ''
  unless response.return_code.upcase.to_s == 'OK'
    @response_body['return_msg'] = response.return_code.upcase
  end

  @response_body['return_code'] = response.code
  @response_body['return_time'] = response.time

  # Return body with correct encoding
  if response.headers_hash['Content-Type'] == "application/json"
    @response_body['return_body'] = JSON.pretty_generate(JSON.parse(response.body)).force_encoding('ISO-8859-1')
  else
    @response_body['return_body'] = response.body.force_encoding('ISO-8859-1')
  end

  @response_body['return_headers'] = response.response_headers.force_encoding('ISO-8859-1')

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
  200
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
  200
end


# Delete Request Collection
delete '/collections/:collection' do
  collection = "requests/#{params[:collection]}.json"

  if File.exists? collection
    File.delete(collection)
  else
    return 404
  end
  200
end


# Delete Request from Collection
delete '/collections/:collection/:request' do
  collection = "requests/#{params[:collection]}.json"

  if File.exists? collection
    stored_collection = JSON.parse File.read(collection)
    stored_collection.delete(params[:request])

    File.open(collection, "w") do |f|
      f.write(stored_collection.to_json)
    end
  else
    return 404
  end
  200
end


# Retrieve list of saved logs
get '/logs' do
  entries = Dir["logs/*.log"]
  entries = entries.map!{ |k| k[5..-5]}
  return { :logs => entries }.to_json
end


# Download log
get '/logs/:log' do
  begin
    send_file "logs/#{params[:log]}.log"
  rescue
    return 404
  end
end


# Delete logs
delete '/logs' do
  logs = Dir["logs/*.log"]

  logs.each do |log|
    File.delete(log)
  end
  200
end


# Delete log entry
delete '/logs/:log' do
  log = "logs/#{params[:log]}.log"

  if File.exists? log
    File.delete(log)
  else
    return 404
  end
  200
end


# Upload file
post '/upload' do

  # Clear directory before writing file
  FileUtils.rm_rf(Dir.glob('tmp/*'))

  unless request.body.nil?
    File.open('tmp/' + params[:file][:filename], 'w') do |f|
      f.write(params[:file][:tempfile].read)
    end
  end
  200
end


# Import from POSTMAN Collection
post '/import' do

  file = 'tmp/postman_import.json'

  # Clear tmp directory before writing file
  FileUtils.rm_rf(Dir.glob('tmp/*'))

  # Save File
  unless request.body.nil?
    File.open(file, 'w') do |f|
      f.write(params[:file][:tempfile].read)
    end
  end

  # Read File
  if File.exists? file
    stored_collection = JSON.parse File.read(file) rescue return 500

    # Data dump of multiple collections
    if stored_collection['collections']
      stored_collection = stored_collection['collections']
    # Single collection
    else
      stored_collection = [stored_collection]
    end
  end

  # Extract File information
  stored_collection.each do |collection|
    new_collection = {}

    collection['requests'].each do |request|
      request_details = {}
      request_details['name'] = request['name']
      request_details['collection'] = collection['name']
      request_details['url'] = request['url']
      request_details['request'] = request['method']
      request_details['headers'] = parse_postman_headers(request['headers'])
      request_details['payload'] = request['data']
      request_details['quantity'] = 1

      new_collection[request['name']] = request_details
    end

    # Write file
    begin
      File.open("requests/#{collection['name']}.json", 'w') do |f|
        f.write(new_collection.to_json)
      end
    rescue
      return 500
    end
  end

  200
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
      Sinatra: #{Sinatra::VERSION} <br/>
      API:     v#{API_VERSION}
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
