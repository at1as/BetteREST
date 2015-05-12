require 'bundler/gem_tasks'
require 'rake/testtask'
#require './lib/better_rest.rb'

#task :default => [:test]

#task :test do
#    ruby "./bin/better_rest"
#    puts "I WAS RUN"
#end

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

desc "Run all tests..."
task :default => :test
