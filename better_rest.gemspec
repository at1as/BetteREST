# coding: utf-8
require 'date'

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name          = "better_rest"
  s.version       = "0.2.4"
  s.licenses	    = ['MIT']
  s.summary       = "REST Test Client"
  s.date          = Date.today.to_s
  s.description   = "Configurable browser-accessible REST API test client"
  s.authors       = ["Jason Willems"]
  s.email         = ["jason@willems.ca"]
  s.homepage      = "https://github.com/at1as/BetteREST"

  s.files         = `git ls-files`.split("\n")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "sinatra", "~>1.4", ">= 1.4.5"
  s.add_runtime_dependency "typhoeus", "~>0.7.1"
  s.add_runtime_dependency "vegas", "~> 0.1", ">= 0.1.11"
  s.add_development_dependency "bundler", "~> 1.7"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rack-test", "~> 0.6.3"
  s.add_development_dependency "capybara", "~> 2.4.4"
  s.add_development_dependency "capybara-webkit", "~> 1.5.1"
  s.add_development_dependency "tilt"
end
