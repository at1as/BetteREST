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


  # Collections - Tests
  def test_wrong_content_type_collection
    File.open('wrong_filetype.txt', 'w') { |f| f.write("JUST A TEST") }
    post "/import", "file" => Rack::Test::UploadedFile.new("wrong_filetype.txt", "text/plain")
    assert_equal(415, last_response.status, "Attempt to upload wrong filetype did not return a 415")
  end

  def test_invalid_file_content_collection
    json = { :hello => "world" }.to_json
    File.open('invalid_content.json', 'w') { |f| f.write(json) }
    post "/import", "file" => Rack::Test::UploadedFile.new("invalid_content.json", "application/json")
    assert_equal(422, last_response.status, "Attempt to upload invalid json filecontent did not return a 422")
  end

  def test_upload_valid_collection
    import_collection
    assert_equal(200, last_response.status, "Attempt to upload valid postman collection did not return a 200")
  end

  def test_delete_test_from_collection
    import_collection
    collection_name = URI.encode('Unit Test Collection')
    request_name = URI.encode('Basic POST - XML')
    delete "/collections/#{collection_name}/#{request_name}"
    assert_equal(200, last_response.status, "Attempt to delete test from collection did not return a 200")
  end

  def test_delete_nonexistent_test_from_collection
    import_collection
    collection_name = URI.encode('Unit Test Collection')
    delete "/collections/#{collection_name}/doesnotexist"
    assert_equal(404, last_response.status, "Attempt to delete nonexistent test from collection did not return a 404")
  end

  def test_delete_collection
    import_collection
    collection_name = URI.encode('Unit Test Collection')
    delete "/collections/#{collection_name}"
    assert_equal(200, last_response.status, "Attempt to delete collection did not return a 200")
  end

  def test_delete_nonexistent_collection
    delete '/collections/doesnotexist'
    assert_equal(404, last_response.status, "Attempt to delete nonexistent collection did not return a 404")
  end

  # Collections - Common
  def import_collection
    postman_collection = File.open('resources/unitTestCollection.json', 'r')
    post '/import', 'file' => Rack::Test::UploadedFile.new(postman_collection, 'application/json')
  end


  # Requests
  def test_send_basic_api_request
    validate_response(DEFAULT_PAYLOAD)  
  end

  # Basic Request Parameters
  def test_send_parallel_api_request
    payload = create_modified_request({quantity: '2'})
    validate_response(payload)
  end

  # Variable Request Parameters
  def test_send_variable_api_request
    # Can't test this here. JS script swaps variables before sending to the server
    payload = create_modified_request({var_key: '{{url}}', var_val: 'www.example.com', url: 'http://{{url}}'})
    validate_response(payload)
  end

  # Request Parameter Persistence
  def test_api_request_settings_persist_refresh
    visit '/'
    fill_in_values
    visit '/'
    validate_filled_in_values(true)
    Capybara.reset_sessions!
  end

  def test_api_request_settings_persist_submission
    visit '/'
    fill_in_values
    find_by_id('submit_request').click
    validate_filled_in_values
    Capybara.reset_sessions!
  end

  def test_header_minimise_persist_refresh
    # Minimise All Content Divs
    visit '/'
    find_by_id('headingReq').click
    find_by_id('headingAuth').click
    find_by_id('headingHead').click
    find_by_id('headingData').click
    find_by_id('headingResults').click
    
    # Validate Content divs are minimised
    visit '/'
    assert_equal('+', find_by_id('headingReq').text[1])
    assert_equal('+', find_by_id('headingAuth').text[1])
    assert_equal('+', find_by_id('headingHead').text[1])
    assert_equal('+', find_by_id('headingData').text[1])
    assert_equal('+', find_by_id('headingResults').text[1])
    
    # Maximise all content divs
    find_by_id('headingReq').click
    find_by_id('headingAuth').click
    find_by_id('headingHead').click
    find_by_id('headingData').click
    find_by_id('headingResults').click
    
    # Validate Content divs are minimised (n.b. &ndash not '-')
    visit '/'
    assert_equal('–', find_by_id('headingReq').text[1])
    assert_equal('–', find_by_id('headingAuth').text[1])
    assert_equal('–', find_by_id('headingHead').text[1])
    assert_equal('–', find_by_id('headingData').text[1])
    assert_equal('–', find_by_id('headingResults').text[1])
    Capybara.reset_sessions!
  end

  #def test_textarea_size_persists_refresh
  #  # SKIP: textarea height set by JS becomes its minimum width in Chrome
  #  #       this is not desirable behaviour, so this feature is not yet implemented
  #  visit '/'
  #  execute_script("document.getElementById('payload').style.height = '300px'")
  #  visit '/'
  #  payload_height = evaluate_script("document.getElementById('payload').style.height")
  #  assert_equal '300px', payload_height
  #  Capybara.reset_sessions!
  #end

  def fill_in_values
    # URL
    select 'POST', :from => 'requestType'
    fill_in 'url', :with => 'http://www.example.com'
    select '10 times', :from => 'times'
    
    # Auth
    fill_in 'usr', :with => 'my_username'
    fill_in 'pwd', :with => 'my_passw0rd'
    
    # Headers
    click_button 'add'
    fill_in 'key1', :with => 'Content-Type'
    fill_in 'value1', :with => 'text/plain'
    click_button 'add' # Leave a blank row inbetween
    click_button 'add'
    fill_in 'key3', :with => 'User-Agent'
    fill_in 'value3', :with => 'BetteRest'
    
    # Payload
    fill_in 'payload', :with => 'some payload data'
    
    # Configuration Details
    find_by_id('dropdown_settings').hover
    find_by_id('dropdown_configuration').click
    check 'followlocation'
    check 'cookies'
    check 'verbose'
    check 'ssl_verifypeer'
    check 'logging'
    fill_in 'timeoutInterval', :with =>'10'
    execute_script('modalHideAll();')
    
    # Variables
    find_by_id('dropdown_settings').hover
    find_by_id('dropdown_variables').click
    fill_in 'varKey0', :with => 'first variable'
    fill_in 'varValue0', :with => 'first value'
    find_by_id('addVariable').click
    fill_in 'varKey1', :with => 'second variable'
    fill_in 'varValue1', :with => 'second value'
    execute_script('modalHideAll();')
  end

  def validate_filled_in_values(page_refresh = false)
    # URL
    assert_equal 'POST', find_field('requestType').value
    assert_equal 'http://www.example.com', find_field('url').value
    assert_equal '10', find_field('times').value

    # Auth
    assert_equal 'my_username', find_field('usr').value
    assert_equal 'my_passw0rd', find_field('pwd').value
    
    # Headers
    if page_refresh
      assert_equal 'Content-Type', find_field('key0').value
      assert_equal 'text/plain', find_field('value0').value
      assert_equal 'User-Agent', find_field('key1').value
      assert_equal 'BetteRest', find_field('value1').value
    else
      assert_equal 'Content-Type', find_field('key1').value
      assert_equal 'text/plain', find_field('value1').value
      assert_equal 'User-Agent', find_field('key3').value
      assert_equal 'BetteRest', find_field('value3').value
    end

    # Payload
    assert_equal 'some payload data', find_field('payload').value
    
    # Configuration Details
    find_by_id('dropdown_settings').hover
    find_by_id('dropdown_configuration').click
    assert_equal true, find_by_id('followlocation').checked?
    assert_equal true, find_by_id('cookies').checked?
    assert_equal true, find_by_id('verbose').checked?
    assert_equal true, find_by_id('ssl_verifypeer').checked?
    assert_equal true, find_by_id('logging').checked?
    assert_equal '10', find_field('timeoutInterval').value
    execute_script('modalHideAll();')
    
    # Variables
    find_by_id('dropdown_settings').hover
    find_by_id('dropdown_variables').click
    assert_equal 'first variable', find_by_id('varKey0').value
    assert_equal 'first value', find_by_id('varValue0').value
    assert_equal 'second variable', find_by_id('varKey1').value
    assert_equal 'second value', find_by_id('varValue1').value
    execute_script('modalHideAll();')
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

  def test_launch_sinatra
    # Script returns true for zero exit status, false for non-zero
    assert true, `ruby "./bin/better_rest"`
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

    assert last_response.ok?
    
    # BASIC
    assert_equal(200, last_response.status, "Sending API GET request did not return a 200")
    assert_instance_of(Float, Float(test_response.fetch('return_time')), "Return time not present or not a number")
    assert_equal(false, test_response.fetch('return_body').nil?, "Response body was empty")

    # OPTIONS
    assert_equal(payload_details['verbose'], test_response_request.fetch('verbose'))
    assert_equal(payload_details['ssl_ver'], test_response_request.fetch('ssl_verifypeer'))
    assert_equal(payload_details['url'], test_response_request.fetch('url'))
    assert_equal(payload_details['timeout'].to_i, test_response_request.fetch('timeout'), payload_details)
  end

end

