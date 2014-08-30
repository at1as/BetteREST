Gem::Specification.new do |s|
  s.name        = "better_rest"
  s.version     = "0.1.1"
  s.licenses	  = ['MIT']
  s.summary     = "REST test Client"
  s.date        = "2014-08-29"
  s.description = "A Configurable REST API test client accessible via the browser."
  s.authors     = ["Jason Willems"]
  s.email       = ["jason@willems.ca"]
  s.homepage    = "https://github.com/at1as/BetteR"
  s.files       = `git ls-files`.split("\n") 
  s.executables << 'better_rest'
end
