# encoding: UTF-8
ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'                                                                                                                                           
require 'rack/test'
require 'capybara'
require 'capybara/webkit'
require 'tilt/erb'
require './lib/better_rest.rb'

class TestBetterRest < MiniTest::Test
  include Rack::Test::Methods
  include Capybara::DSL

  DEFAULT_PAYLOAD = '{"headers":{},
                      "request":"GET",
                      "url":"http://www.example.com",
                      "quantity":"1",
                      "payload":"",
                      "user":"",
                      "password":"",
                      "var_key":"",
                      "var_val":"",
                      "redirect":true,
                      "cookies":true,
                      "verbose":true,
                      "ssl_ver":false,
                      "logging":false,
                      "timeout":"1",
                      "file":"",
                      "show_url":"",
                      "show_auth":"",
                      "show_head":"",
                      "show_payload":"",
                      "show_results":"",
                      "data_height":100}'

  def app
    Capybara.app = Sinatra::Application
  end

  def setup
    Capybara.current_driver = :webkit
  end

  # Directory structure
  def test_directories_exist
    assert_equal(true, File.directory?("./tmp"), "tmp directory does not exist!")
    assert_equal(true, File.directory?("./logs"), "log directory does not exist!")
    assert_equal(true, File.directory?("./requests"), "requests directory does not exist!")
  end

  # URL Navigation
  def test_index_page_no_redirect
    get '/'
    assert last_response.ok?
    assert_equal(200, last_response.status, "Index page did not return a 200")
    assert_equal("/", last_request.fullpath, "/")
  end

  def test_env_page_no_redirect
    get '/env'
    assert last_response.ok?
    assert_equal(200, last_response.status, "Env page did not return a 200")
    assert_equal("/env", last_request.fullpath, "/env")
  end

  def test_get_all_log_entries
    get '/logs'
    assert last_response.ok?
    assert_equal(200, last_response.status, "Get all logs did not return a 200")
    assert_equal("/logs", last_request.fullpath, "/logs")
  end

  def test_get_all_requests
    get '/savedrequests'
    assert last_response.ok?
    assert_equal(200, last_response.status, "Get all saved requests did not return a 200")
    assert_equal("/savedrequests", last_request.fullpath)
  end

  # Redirect for Invalid URL
  def test_not_found_redirect
    get '/this_page_does_not_exist'
    assert last_response.redirect?
    follow_redirect!
    assert_equal("/", last_request.fullpath)
  end

  def test_not_found_unicode_redirect
    get URI.encode('/this_page_does_not_exist_unicode_¨øˆƒ∆∂˚¬å∆ƒ∂åºª')
    assert last_response.redirect?
    follow_redirect!
    assert_equal("/", last_request.fullpath)
  end

  # Logging
  def test_retrieve_non_existent_log_entry
    get '/logs/does-not-exist.log'
    follow_redirect!
    assert_equal(200, last_response.status, "Invalid log entry did not return a redirect")
    assert_equal("/", last_request.fullpath)
  end

  def test_retrieve_log_entry
    log = <<-ENTRY
      THIS IS A TEST LOG ENTRY 
    ENTRY
    File.open('logs/2000-01-01.log', 'a') { |file| file.write(log) }
    get '/logs/2000-01-01'
    assert_equal(200, last_response.status, "Attempt to get log file did not return 200")
    assert_equal("/logs/2000-01-01", last_request.fullpath)
  end

  def test_delete_log_entry
    File.open('logs/2000-01-01.log', 'a') { |file| file.write("ensuring log exists") }
    delete '/logs/2000-01-01'
    assert_equal(200, last_response.status, "Attempt to delete log did not return 200")
    assert_equal(false, File.exists?("./logs/2000-01-01.log"), "log file still exists after deletion")
  end

  def test_delete_non_existent_log_entry
    delete '/logs/does-not-exist'
    assert_equal(404, last_response.status, "Attempt to delete non existent log did not return 404")
  end

  # Collection Import
  def test_wrong_content_type_upload
    File.open('wrong_filetype.txt', 'w') { |f| f.write("JUST A TEST") }
    #file = Rack::Test::UploadedFile.new("wrong_filetype.txt", "text/plain")
    #file = Rack::Multipart::UploadedFile.new("wrong_filetype.txt", "text/plain")
    #env = Rack::MockRequest.env_for('/import', method: "POST", params: {:text_source => file } )
    #app.call env #r = Rack::Request.new(env)
    
    #post '/import', file: "THIS IS THE WRONG FORMAT"

    #post "/import", "file" => Rack::Multipart::UploadedFile.new("wrong_filetype.txt", "text/plain")  #Rack::Test::UploadedFile.new("wrong_filetype.txt", "text/plain")
    
    post "/import", "file" => Rack::Test::UploadedFile.new("wrong_filetype.txt", "text/plain")
    #puts last_response.inspect
    #last_response.each do |x|
    #  puts "\n\n#{x}\n #{last_response[x]}"
    #end
    #post '/upload', :file => file
    #puts last_response
    #puts last_response.server_error?
    #puts "ABC #{last_response.methods}"
    #puts r.methods
    assert_equal(415, last_response.status, "Attempt to upload wrong filetype did not return a 415")
  end

  def test_invalid_file_contents
    json = { :hello => "world" }.to_json
    File.open('invalid_content.json', 'w') { |f| f.write(json) }
    post "/import", "file" => Rack::Test::UploadedFile.new("invalid_content.json", "application/json")
    #File.open('tmp.html', 'w') { |f| f.write(last_response.body) }
    #post '/import', file: Rack::Multipart::UploadedFile.new("invalid_content.json", "application/json") #{ hello: "world" }
    assert_equal(422, last_response.status, "Attempt to upload invalid json filecontent did not return a 422")
  end


  # Requests
  def test_send_basic_api_request
    payload = '{"headers":{},"request":"GET","url":"http://www.example.com","quantity":"1","payload":"","user":"","password":"",
                  "var_key":"","var_val":"","redirect":true,"cookies":true,"verbose":true,"ssl_ver":false,"logging":false,"timeout":"1",
                  "file":"","show_url":"","show_auth":"","show_head":"","show_payload":"","show_results":"","data_height":100}'
    validate_response(DEFAULT_PAYLOAD)  
  end

  # Basic Request Parameters
  def test_send_parallel_api_request
    payload = create_modified_request({quantity: '2'})
    validate_response(payload)
  end

  # Variable Request Parameters
  def test_send_variable_api_request
    payload = create_modified_request({var_key: '{{url}}', var_val: 'www.example.com', url: 'http://{{url}}'})
    validate_response(payload)
  end

  # Request Option Parameters
  def test_verbose_api_request
    payload = create_modified_request({verbose: false})
    validate_response(payload)
    #visit '/'
    #inline_response = last_response.body.gsub!(/(\S)[^\S\n]*\n[^\S\n]*(\S)/, '\1 \2')
    #puts "ABC: \n\n\n\n #{page.body} \n\n\n\n :ABC"
    #assert inline_response.include?('<input type="checkbox" name="verbose" id="verbose" class="checkbox" style="float:right" >')
    #visit "/request", payload, {"Content-Type" => "application/json"}
    visit "/"
    #assert page.has_content?('<input type="checkbox" name="verbose" id="verbose" class="checkbox" style="float:right" >')
    puts page.body
    assert page.has_content?("html")

    payload = create_modified_request({verbose: true})
    validate_response(payload)
    get '/'
    inline_response = last_response.body.gsub!(/(\S)[^\S\n]*\n[^\S\n]*(\S)/, '\1 \2')
    assert inline_response.include?('<input type="checkbox" name="verbose" id="verbose" class="checkbox" style="float:right" checked>')
  end

  def test_ssl_verify_api_request
    payload = create_modified_request({ssl_ver: false})
    validate_response(payload)
    payload = create_modified_request({ssl_ver: true})
    validate_response(payload)
  end

  def test_logging_api_request
    log_file = "logs/" + Time.now.strftime('%Y-%m-%d') + ".log"
    before_length = File.open(log_file, "r").readlines.size rescue 0
    payload = create_modified_request({logging: true})
    validate_response(payload)
    after_length = File.open(log_file, "r").readlines.size rescue 0
    assert(before_length < after_length, "Log file was not appended")
  end
  
  def test_timeout_api_request
    payload = create_modified_request({timeout: 10})
    validate_response(payload)
    payload = create_modified_request({timeout: 1})
    validate_response(payload)
  end

  # Request Page Layout Parameters
  def test_show_url_api_request
    payload = create_modified_request({show_url: false})
    validate_response(payload)
    payload = create_modified_request({show_url: true})
    validate_response(payload)
  end
  
  def test_show_auth_api_request
    payload = create_modified_request({show_auth: false})
    validate_response(payload)
    payload = create_modified_request({show_auth: true})
    validate_response(payload)
  end

  def test_show_head_api_request
    payload = create_modified_request({show_head: false})
    validate_response(payload)
    payload = create_modified_request({show_head: true})
    validate_response(payload)
  end
 
  def test_show_paylaod_api_request
    payload = create_modified_request({show_payload: false})
    validate_response(payload)
    payload = create_modified_request({show_payload: true})
    validate_response(payload)
  end

  def test_show_results_api_request
    payload = create_modified_request({show_results: false})
    validate_response(payload)
    payload = create_modified_request({show_results: true})
    validate_response(payload)
  end
  
  def test_data_height_api_request
    payload = create_modified_request({data_height: 30})
    validate_response(payload)
    payload = create_modified_request({data_height: 130})
    validate_response(payload)
  end
  
  # API Methods
  def create_modified_request(new_params)
    payload = JSON.parse(DEFAULT_PAYLOAD)
    new_params.each do |key, value|
      payload[key] = value
    end
    payload.to_json
  end

  def validate_response(payload)
    post "/request", payload, {"Content-Type" => "application/json"}
    
    payload_details = JSON.parse(payload)
    test_response = JSON.parse(last_response.body)
    test_response_request = JSON.parse(JSON.parse(last_response.body)['request_options'])

    #puts "\n\n\n\nABC #{test_response}\n\n#{test_response.is_a? Hash}\n\n"
    #puts "\n\n\n#{payload_details}"
    assert last_response.ok?
    
    # BASIC
    assert_equal(200, last_response.status, "Sending API GET request did not return a 200")
    assert_instance_of(Float, Float(test_response.fetch('return_time')), "Return time not present or not a number")
    assert_equal(false, test_response.fetch('return_body').nil?, "Response body was empty")
    # OPTIONS
    assert_equal(payload_details['verbose'], test_response_request.fetch('verbose'))
    assert_equal(payload_details['ssl_ver'], test_response_request.fetch('ssl_verifypeer'))
    assert_equal(payload_details['url'], test_response_request.fetch('url'))
    #assert_equal(payload_details['logging'], test_response_request.fetch('logging'))
    assert_equal(payload_details['timeout'].to_i, test_response_request.fetch('timeout'), payload_details)
    # LAYOUT
    
    #assert_equal(payload_details['show_url'], test_response_request.fetch('show_url'))
    #assert_equal(payload_details['show_auth'], test_response_request.fetch('show_auth'))
    #assert_equal(payload_details['show_head'], test_response_request.fetch('show_head'))
    #assert_equal(payload_details['show_data'], test_response_request.fetch('show_data'))
    #assert_equal(payload_details['show_results'], test_response_request.fetch('show_results'))
    #assert_equal(payload_details['data_height'], test_response_request.fetch('data_height'))
  end

end

