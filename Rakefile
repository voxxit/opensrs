require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

$LOAD_PATH.unshift("lib")

require 'rake'
require 'opensrs'

begin
  require 'jeweler'
  
  Jeweler::Tasks.new do |gem|
    gem.name        = "opensrs"
    gem.version     = OpenSRS::Version::VERSION
    gem.summary     = "Provides support to utilize the OpenSRS API with Ruby/Rails."
    gem.description = "Provides support to utilize the OpenSRS API with Ruby/Rails."
    gem.email       = "josh@voxxit.com"
    gem.homepage    = "http://github.com/voxxit/opensrs"
    gem.license     = "MIT"
    gem.authors     = ["Josh Delsman"]
    
    # Requirements are in Gemfile
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = FileList['lib/**/*.rb']
end